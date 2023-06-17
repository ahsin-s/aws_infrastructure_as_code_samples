from django.shortcuts import render, redirect

from models import Whisper


# view to retrieve the whispers in sorted order by pub date
def index(request):
    # query all records in Whisper model
    whispers = Whisper.objects.all().order_by('-pub_date')
    # render the index.html template with the whispers
    return render(request, 'whisper/index.html', {
        'whispers': whispers
    })


def detail(request, whisper_id):
    # query the whisper with the given id
    whisper = Whisper.objects.get(id=whisper_id)
    # render the detail.html template with the whisper
    return render(request, 'whisper/detail.html', {
        'whisper': whisper
    })


# view for adding new entries to Whisper model
def add(request):
    # create a new whisper
    whisper = Whisper(
        whisper=request.POST['content'],
    )
    # save the new whisper
    whisper.save()
    # redirect to the index page
    return redirect('/whisper/')
