# Chat Websocket Server

A websocket server using ruby/sinatra for chat clients. It supports mulitple rooms, and automatic banning of users who flood the chat

# Connecting

Join a room by connecting to the websocket on the appropriate url.

    /chat/<room_name>?key=<key>&username=<username>

The key is an sha1 hash that is provided to the client. It is generated using the username and the room name. This ensures that the username and the room name have not been changed before the request is made.

If the key is incorrect a http `403` will be returned

# Authentication

See `app.rb` for the method used for generating the key

# Websocket

All communication with the server takes the form of JSON objects. These are structured in the following way:

    {
        event: string
        data: object
    }

## Messages

### chat
When a `chat` message is received it will be relayed to all other users in the room. Some validation is done on the username and the content, but in general it is sent unmodified.

    {
        username: string
        content: string
        color: string (optional)
    }

### ping
When a ping message is received by the server, a `pong` will sent back immediately with the same content. This will allow the client to calculate the latency to the server.

### history
On connect a history message is sent to the client to give them the recent history of the room while they weren't there. It won't give the full history, but it will give the last 100 message or so.

    [
        {
            username: string,
            content: string,
            color: string
            created_date: Time
        },
        ...
    ]

### countChanged
When a user joins or leaves a room a countChanged message will be sent to notify the clients of the new number of people in the room.

    {
        connected: int
        chatting: int
    }

