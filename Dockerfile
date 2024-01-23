# Use an official Python runtime as a parent image
FROM python:3.10

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Set execute permissions for Python
RUN chmod +x /usr/local/bin/python

# Install dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Install Gunicorn
RUN pip install gunicorn

# Copy project
COPY . /app/

# Set environment variables for your Django project
ENV DJANGO_DEBUG=False
ENV DJANGO_SETTINGS_MODULE TTT_GameDev_Auth.settings

# Expose the port that your application will listen on (if needed)
# EXPOSE 8001

# Set the command to run your Django application with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8001", "your_project_name.wsgi:application"]
