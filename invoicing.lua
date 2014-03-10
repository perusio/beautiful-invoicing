-- @file   invoice_number.lua
-- @author António P. P. Almeida <appa@perusio.net>
-- @date   Tue Jan 21 09:10:26 2014
--
-- @brief Creates and maintains an invoice numbering scheme.
--

-- Copyright (C) 2014 António P. P. Almeida <appa@perusio.net>

-- Author: António P. P. Almeida <appa@perusio.net>

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- Except as contained in this notice, the name(s) of the above copyright
-- holders shall not be used in advertising or otherwise to promote the sale,
-- use or other dealings in this Software without prior written authorization.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- Get the CDB library.
local cdb = require 'cdb'
-- CDB functions.
local open = cdb.open
local make = cdb.make

-- Get CJSON.
local cjson = require 'cjson'
-- CJSON functions.
local decode = cjson.decode
local encode = cjson.encode

-- Import from the global environment.
local read = io.read
local close = io.close
local time = os.time
local format = string.format
local pairs = pairs
local ipairs = ipairs
local assert = assert
local print = print

-- Avoid polluting the global environment.
-- If we are in Lua 5.1 this function exists.
if _G.setfenv then
   setfenv(1, {})
else -- Lua 5.2.
   _ENV = nil
end

-- Module table.
local _M = { _VERSION = '0.1', _NAME = 'invoicing', }

-- Invoice CDB related files.
_M.invoice_cdb = 'invoice.cdb'
_M.invoice_tmp = format('%s.tmp', _M.invoice_cdb)

-- Client record schema.
_M.client_schema = {
   'client',
   'address',
   'invoice_number',
}

--- Get a client record.
--
-- @param string client_name
--   The client name.
-- @return table
--   The client record as a table.
--
function _M.get_client_record(client_name)
   -- Create a reader for the invoice DB.
   local cdb = assert(open(_M.invoice_cdb))

   for k, v in cdb:pairs() do
      if (k == client_name) then
         -- Return the decoded value.
         return decode(v)
      end
   end
   -- If we didn't found a client record return false.
   return false
end

--- Update an invoice number.
--
-- @param string client_name
--   The client name.
-- @return number
--   The invoice number or nil.
--
function _M.get_set_invoice_number(client_name)

   -- Try to get the current record.
   local current_record = _M.get_client_record(client_name)
   -- If there's a record then update the invoice number.
   if (current_record) then
      current_invoice_number = current_record.invoice_number
      -- Increment the invoice number.
      current_record.invoice_number = current_invoice_number + 1
      -- Update the time stamp.
      current_record.timestamp = time()
      -- Update the client record with the new invoice number.
      _M.update_client_record(client_name, current_record)
      -- Return the previous invoice number.
      return current_invoice_number + 1
   else
      return nil
   end
end

--- Update or create a client record.
--
-- @param string client_name
--   The client name.
-- @param table values
--   The values of the record.
-- @return nothing
--   Side effects only.
--
function _M.update_client_record(client_name, values)
   local not_empty = false

   -- See if we have an existing record or not.
   record = _M.get_client_record(client_name) or {}

   -- Loop over the schema inserting the values.
   for _, k in ipairs(_M.client_schema) do
      if (values[k] ~= nil) then
         record[k] = values[k]
         -- Set the value so that we know if the table has at least
         -- one entry.
         not_empty = not_empty or true
      end
   end
   -- If we're setting up a new client record then initialize the invoice number.
   if (record.invoice_number == nil) then
      record.invoice_number = 0
   end
   -- Update/insert the record if it's in the scheme.
   if (not_empty) then
      -- Update the timestamp.
      record.timestamp = time()
      -- Create a setter for updating/inserting the record.
      -- Instantiate a CDB constructor.
      local cdb_mk = assert(make(_M.invoice_cdb, _M.invoice_tmp))
      -- Update/insert the record.
      cdb_mk:add(client_name, encode(record), 'replace0')
      -- Destroy the setter.
      assert(cdb_mk:finish())
   end
end

--- Accessor for the client record.
--
-- @param string client_name
--   The client name.
-- @param string field_name
--   The field to be fetched for this client record.
-- @return string|number
--   The value of the given field for the given client.
--
function _M.get_client_field(client_name, field_name)
   local current_client_record = _M.get_client_record(client_name) or false

   -- If the current record exists loop until we find the desired
   -- field.
   if (current_client_record) then
      for k, v in pairs(current_client_record) do
         -- If we find the field (key) return the corresponding value.
         if (field_name == k) then
            return v
         end
      end
   end
   -- If we didn't found anything return nil.
   return nil
end

--- Get the invoice code. The way an invoice code to be printed
--  is built.
--
-- @param string client_name
--   The client name.
-- @return string
--   The invoice code.
function _M.get_invoice_code(client_name)
   -- Concatenate the client name with the invoice number.
   return format('%s-%03d', client_name, get_set_invoice_number(client_name))
end

return _M
