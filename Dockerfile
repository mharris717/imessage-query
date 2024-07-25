# Use an official Ruby runtime as a parent image
FROM ruby:3.1

RUN mkdir -p /dbdata

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY src /app

# Install any needed packages specified in Gemfile
COPY Gemfile* /app/
COPY config.ru /app
RUN bundle install

# Make port 4567 available to the world outside this container
EXPOSE 4567

# Define environment variable
ENV NAME World
ENV DB_PATH /dbdata/chat.db

# COPY chat2.db /dbdata/chat.db


# Run serve.rb when the container launches
# CMD ["ruby", "serve.rb"]
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]
