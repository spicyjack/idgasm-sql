# WADTools Callbacks #

## Program control flow ##
- After the program starts, a "controller" object is created, then control is
  passed to it
  - `$controller->run`
- _Controller_ sets up the other objects, and passes references to itself to
  the other objects
- _Controller_ object will then pull data from _Model_ (the model), and call
  `update_view()` on the view
- View will call ???

## Object Methods/Messages ##

View methods
- `read_view(name => $view_name)`
  - Invoked by: _Controller_
  - Purpose: Response to the _View_ sending `view_changed` to the _Controller_
  - Response: _View_ returns view data to the _Controller_
- `update_view(name => $view_name)`
  - Invoked by: _Controller_
  - Purpose: When data in _Model_ (model) has changed
  - Response: _View_ calls `read_data(view_name)`
- `request_success(name => $view_name)`
  - Invoked by: _Controller_
  - Purpose: When an operation in progress completes successfully
  - Response: None
- `request_failure(name => $view_name)`
  - Invoked by: _Controller_
  - Purpose: When an operation in progress fails to complete successfully
  - Response: None
- `request_update(level => log_level, id => log_id, message => $msg)`
  - Invoked by: _Controller_
  - Purpose: When an operation in progress wants to update the user with the
    status of the operation
  - Response: None

Controller methods
- `read_data(name => view_name)`
  - Invoked by: _View_
  - Purpose: Response by the _View_ after receiving a
    `updated_data(name => view_name)` message from the _Controller_
  - Response: _Controller_ Returns updated data for the _View_ to display
- `update_data(name => view_name)`
  - Invoked by: _View_
  - Purpose: Causes the _Controller_ to call `read_view(name => view_name)`
    using the view callback object
  - Response: _Controller_ calls `read_view(name => view_name)` to get the
    updated data from the _View_, and also decides whether or not _Model_
    needs to be updated.  If _Model_ needs to be updated, calls the
    appropriate _Model_ method
    - `create/update/read/delete`
- `request_update(level => log_level, id => log_id, message => $msg)`
  - Invoked by: _Model_
  - Purpose: Updates the _Controller_ with the status of a request; _Model_
    will include information about the successful request (request ID or type,
    or both)
  - Response: _Controller_ updates _View_ based on business rules/need
- `request_success(id => log_id, message => $msg)`
  - Invoked by: _Model_
  - Purpose: Lets the _Controller_ know that a previous request was successful;
    _Model_ will include information about the successful request (request ID
    or type, or both)
  - Response: _Controller_ updates _View_ based on business rules/need
- `request_failure(id => log_id, message => $msg)`
  - Invoked by: _Model_
  - Purpose: Lets the _Controller_ know that a previous request failed;
    _Model_ will include information about the failed request (request ID or
    type, or both)
  - Response: _Controller_ updates _View_ based on business rules/need,
    possibly lets user know something failed
- `trace/debug/info/warn/error/fatal(id => log_id, message => $msg)`
  - Invoked by: _Model_, _Controller_
  - Purpose: Same as `request_update()` above, but with log levels baked in
  - Response: _Controller_ updates _View_ based on the current log level; if
    the current log level is less than the log level in the message,
    `request_update()` is not called on the _View_
    is sent

Model methods
- All _Model_ methods are invoked by the _Controller_, and will cause
  _Model_ to invoke one or more of the `request_*` methods during processing
  (`request_update`), as well as after processing is complete
  (`request_success`/`request_failure`)
- `create(name => table_name, info => hash_with_table_info)`
  - Create a table using info read from another database
- `read_schema(db => database_object, name => table_name)`
  - Read schema from a database
- `read_data(db => database_object, name => table_name)`
  - Read data from a database
- `update(db => database_to_update, data => update_data)`
  - Add/update records to a database
- `delete(data => data_to_delete, name => table_name)`
  - Delete records from a database
  - Probably never be used for `dump_o_matic`

vim: filetype=markdown shiftwidth=2 tabstop=2

