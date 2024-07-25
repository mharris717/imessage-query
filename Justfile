copydb:
    cp ~/Library/Messages/chat.db .

docker: 
    docker run -P --name imessage-serve -v `pwd`/chat.db:/dbdata/chat.db:ro mharris717/imessage-query

docker-port:
    docker port imessage-serve 4567

docker-open:
    open http://`just docker-port`