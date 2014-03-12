-- Tests for the invoicing facility using luaunit.

local lower = string.lower
local gsub = string.gsub
local inv = require 'invoicing'

require 'luaunit'

lu = LuaUnit

TestInvoicing = {} -- test class

-- Setup function that builds the test data.
function TestInvoicing:setup()
   -- Get the test client data.
   local sr = {}
   sr.client = 'New Client'
   local client_name = lower(gsub(sr.client, '[ -]+', '_'))
   sr.address = [[ New Client Inc \\
Street X
Some Place 8967\\
Silk Road 126789\\
Atlantis ]]
   sr.invoice_number = 0
   return client_name, sr
end

-- Write to and read from database.
function TestInvoicing:write_read()
   -- Get the value.
   local client_name, sr = TestInvoicing:setup()
   -- Create the client record.
   inv.update_client_record(
      client_name, sr)
   -- Read the client record.
   local r = inv.get_client_record(client_name)
   for k,v in pairs(sr) do
      assertEquals(v, r[k])
   end
end

-- Increase the invoice number.
function TestInvoicing:invoice_number(name)
   local n = inv.get_set_invoice_number(name)
   assertEquals(inv.get_set_invoice_number(name), n + 1)
   assertEquals(inv.get_set_invoice_number(name), n + 2)
   assertEquals(inv.get_set_invoice_number(name), n + 3)
   return n + 3
end

-- Test all the fields.
function TestInvoicing:get_client_fields()
   local client_name, sr = TestInvoicing:setup()
   local n = TestInvoicing:invoice_number(client_name)
   sr.invoice_number = n
   local r = inv.get_client_record(client_name)

   for _, f in ipairs(inv.client_schema) do
      assertEquals(r[f], sr[f])
   end
end

-- lu:setOutputType('TAP')
lu:setVerbosity(5)
lu:run('TestInvoicing:write_read')
lu:run('TestInvoicing:get_client_fields')
