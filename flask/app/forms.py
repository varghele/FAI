from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField
from wtforms.validators import DataRequired
from flask_wtf.file import FileField, FileAllowed, FileRequired

from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField
from wtforms.validators import DataRequired
from flask_wtf.file import FileField, FileAllowed, FileRequired


class NOESYForm(FlaskForm):
    # Membrane Type Field
    membraneType = StringField('Type of the Membrane',
                               validators=[DataRequired()],
                               render_kw={"placeholder": "Enter the type of membrane"})

    # Order of the Peaks Field
    peaksOrder = StringField('Order of the Peaks',
                             validators=[DataRequired()],
                             render_kw={"placeholder": "Enter the order of peaks (e.g., 1, 2, 3)"})

    # Display Order of Peaks Field
    displayOrder = StringField('Display Order of Peaks',
                               validators=[DataRequired()],
                               render_kw={"placeholder": "Enter display order of peaks"})

    # Chemical Name Field
    chemicalName = StringField('Name of the Chemical',
                               validators=[DataRequired()],
                               render_kw={"placeholder": "Enter chemical name"})

    # PPM Values Field
    ppmValues = StringField('PPM Values of the Chemical Peaks',
                            validators=[DataRequired()],
                            render_kw={"placeholder": "Enter PPM values (e.g., 1.23, 2.34, 3.45)"})

    # Integrated Values for Mixing Times Fields
    integratedValues0ms = FileField('Integrated Values for 0ms',
                                    validators=[FileRequired(), FileAllowed(['csv', 'txt'], 'CSV or TXT files only!')])

    integratedValues100ms = FileField('Integrated Values for 100ms',
                                      validators=[FileRequired(),
                                                  FileAllowed(['csv', 'txt'], 'CSV or TXT files only!')])

    integratedValues200ms = FileField('Integrated Values for 200ms',
                                      validators=[FileRequired(),
                                                  FileAllowed(['csv', 'txt'], 'CSV or TXT files only!')])

    integratedValues300ms = FileField('Integrated Values for 300ms',
                                      validators=[FileRequired(),
                                                  FileAllowed(['csv', 'txt'], 'CSV or TXT files only!')])

    integratedValues500ms = FileField('Integrated Values for 500ms',
                                      validators=[FileRequired(),
                                                  FileAllowed(['csv', 'txt'], 'CSV or TXT files only!')])

    # Submit Button
    submit = SubmitField('Submit Data')
