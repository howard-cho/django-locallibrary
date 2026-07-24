from django.shortcuts import render
from django.views import generic

# Create your views here.
from .models import Book, BookInstance, Author, Genre

class BookListView(generic.ListView):
    model = Book
    context_object_name = 'book_list' # Your own name for the list as a template variable
    # queryset = Book.objects.filter(title__icontains='war')[:5] # Get 5 books containing the title 'war'
    template_name = 'books/my_arbitrary_template_name_list.html' # Specify your own template name/location

class BookDetailView(generic.DetailView):
    model = Book

def index(request):
    """View function for the home page of the site."""

    # Generate counts of some of the main objects
    num_books = Book.objects.all().count()
    num_instances = BookInstance.objects.all().count()

    # Available books (status = 'a')
    num_instances_available = BookInstance.objects.filter(status__exact='a').count()

    # Then 'all()' is implied by default.
    num_authors = Author.objects.count()

    # Available genres
    num_genres = Genre.objects.count()

    context = {
        'num_books': num_books,
        'num_instances': num_instances,
        'num_instances_available': num_instances_available,
        'num_authors': num_authors,
        'num_genres': num_genres
    }

    # Render the HTML template index.html with the data in the context variable
    return render(request, 'index.html', context=context)