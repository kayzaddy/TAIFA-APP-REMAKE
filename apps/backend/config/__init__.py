"""TAIFA backend Django project.

Importing the Celery app here ensures shared tasks are registered when Django
starts. Celery is optional in local/test runs (tasks run eagerly).
"""
from .celery import app as celery_app

__all__ = ("celery_app",)
