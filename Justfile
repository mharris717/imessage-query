copydb:
    rm chatc.db || true 
    cp /Users/mharris717/Library/Messages/chat.db chatc.db

docker: 
    cp ~/Library/Messages/chat.db chat2.db && docker run -P --name imessage-serve -v `pwd`/chat2.db:/dbdata/chat.db:ro imessage

docker-port:
    docker port imessage-serve 4567

docker-open:
    open http://`just docker-port`