# Use an official Python runtime as a parent image
FROM python:3.10

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Copy project files to the container
COPY . /app/

# Install project dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set environment variables for your Django project
ENV DJANGO_DEBUG=False
ENV DJANGO_SETTINGS_MODULE TTT_GameDev_Auth.settings

# Expose the port that your application will listen on (if needed)
EXPOSE 8001

# Set the command to run your Django application with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8001", "your_project_name.wsgi:application"]
