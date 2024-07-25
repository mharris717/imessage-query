# iMessage Query

This project provides a simple web server to access and query iMessage data from a macOS Messages database.

## Prerequisites

- Ruby
- Sinatra
- Docker (optional)
- [Just](https://github.com/casey/just) (optional)
    - If you don't install just, copy commands from Justfile and run by hand

 

## Usage

### Docker

1. Copy the Messages database:
   ```
   just copydb
   ```

   *This step is only necessary because mounting your Messages DB directly from `~/Library/Messages/chat.db` doesn't work properly.*

2. Run the server:
   ```
   just docker
   ```

3. Open in browser:
   ```
   just docker-open
   ```

### Local Development

1. Clone this repository.
2. Install dependencies:
   ```
   bundle install
   ```

3. Run the server:
   ```ruby
   ruby src/serve.rb
   ```

4. Access the API at `http://localhost:4567`



## API Endpoints

### GET /

Retrieves messages with pagination.

Query parameters:
- `page`: Page number (default: 1)
- `per_page`: Number of messages per page (default: 300)
- `chat_name`: Filter by chat name

Response format:
```json
{
  "messages": [
    {
      "id": "string",
      "chat_name": "string",
      "text": "string",
      "date": "string",
      "is_from_me": boolean,
      "chat": {
        "id": "string",
        "desc": "string",
        "display_name": "string",
        "service_name": "string",
        "handles": ["string"]
      }
    }
  ],
  "meta": {
    "page": integer,
    "per_page": integer,
    "total_pages": integer,
    "total_count": integer
  }
}
```