provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Variables
variable "project_id" {
  default = "fischerai"
}

variable "region" {
  default = "europe-west10"
}

variable "zone" {
  default = "europe-west10-b"
}

variable "bucket_name" {
  default = "fischerai-1h1hnoesy-bucket"
}

variable "zone_name" {
  default = "fischerai-dns-zone"
}

variable "instance_name" {
  default = "nginx-main"
}

variable "machine_type" {
  default = "e2-micro"
}

variable "github_repo" {
  default = "https://github.com/varghele/FAI.git"
}

variable "startup_script" {
  default = "nginx-startup.sh"
}

# Create the Google Cloud Storage bucket
resource "google_storage_bucket" "bucket" {
  name                        = var.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }

  public_access_prevention = "enforced"
}

# Create DNS managed zone
resource "google_dns_managed_zone" "dns_zone" {
  name        = var.zone_name
  dns_name    = "fischerai.com."
  description = "Managed zone for fischerai.com"
  visibility  = "public"
  dnssec_config {
    state = "off"
  }
}

# Create the Google Compute Engine instance with Nginx
resource "google_compute_instance" "nginx_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone


  boot_disk {
    auto_delete = true
    device_name = var.instance_name

    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/fischerai/regions/europe-west10/subnetworks/default"
  }

  tags = ["http-server", "https-server", "tag-nginx-main"]

  metadata = {
    GITHUB_REPO     = var.github_repo
  }

  metadata_startup_script = file(var.startup_script)

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "506359823535-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }
}

# Allow HTTP traffic on port 80
resource "google_compute_firewall" "allow_http" {
  name    = "nginx-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["tag-nginx-main"]
  direction   = "INGRESS"
  description = "Allow HTTP traffic on port 80"
  source_ranges = ["0.0.0.0/0"]
}

#  Allow TCP ingress on port 22
resource "google_compute_firewall" "nginx_allow_ssh" {
  name    = "nginx-allow-ssh-tcp"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["tag-nginx-main"]

  description = "Allow TCP traffic on port 22"
  direction   = "INGRESS"
  source_ranges = ["0.0.0.0/0"] # This allows SSH access from any IP. Restrict if needed.
}
