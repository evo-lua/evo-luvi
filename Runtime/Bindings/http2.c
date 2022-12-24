#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Define a structure to represent a HTTP message
typedef struct {
  char method[16];
  char uri[256];
  char http_version[16];
  struct {
    char *name;
    char *value;
    struct header *next;
  } *headers;
  char *body;
} http_message_t;

// Define callback functions to handle the various events that the parser can trigger
void on_method(http_message_t *http_message, const char *method, size_t length) {
  strncpy(http_message->method, method, length);
  http_message->method[length] = '\0';
}

void on_uri(http_message_t *http_message, const char *uri, size_t length) {
  strncpy(http_message->uri, uri, length);
  http_message->uri[length] = '\0';
}

void on_http_version(http_message_t *http_message, const char *http_version, size_t length) {
  strncpy(http_message->http_version, http_version, length);
  http_message->http_version[length] = '\0';
}

void on_header(http_message_t *http_message, const char *name, size_t name_length, const char *value, size_t value_length) {
  // Allocate memory for the header name and value
  char *header_name = malloc(name_length + 1);
  char *header_value = malloc(value_length + 1);

  // Copy the header name and value into the allocated memory
  strncpy(header_name, name, name_length);
  header_name[name_length] = '\0';
  strncpy(header_value, value, value_length);
  header_value[value_length] = '\0';

  // Add the header to the linked list of headers
  struct header *new_header = malloc(sizeof(struct header));
  new_header->name = header_name;
  new_header->value = header_value;
  new_header->next = http_message->headers;
  http_message->headers = new_header;
}

void on_body(http_message_t *http_message, const char *body, size_t length) {
  // Allocate memory for the body
  http_message->body = malloc(length + 1);

  // Copy the body into the allocated memory

