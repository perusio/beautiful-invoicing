# Beautiful Invoicing

## Introduction

Beautiful invoicing is a [LuaTeX](http://ww.luatex.org) based software
for producing beautiful invoices as TeX/LaTeX can easily produce.

It uses [`tinycdb`](http://www.corpit.ru/mjt/tinycdb.html) to store
the client records keyed by client name.

The emphasis in _lowtech_ is to make it as portable and as simple as
possible.

It can be altered to suit your needs. Both in the client information
record storage and in the output.

Each record consists of three fields:

 + client: the client full name;

 + address: the client address, a multiline Lua string with all the
   data;

 + invoice_number: the number of the last issued invoice, when no
   invoices have been issued this value is zero;

 + timestamp: a UNIX timestamp of the last update to the record.

 + issued: a list of issued invoices, keyed by the issue date
   timestamp. Each issued invoice is composed of:

     + invoice_number: the invoice number;

     + total: the total value of the invoice;

     + filename: the full path to the invoice LaTeX file.

The rationale behind this approach is to avoid having a huge list of
clients in LaTeX/TeX format, but instead having it in a database so
that it can easily be queried. 

Avoidance of SQL parsing was one of the objectives. There's no point
in using SQL since there's very little volume of information and the
queries that are useful are quite simple.

Since `tinycdb` does atomic updates we're sure that no information is
lost, thus guaranteeing the integrity of the client database.

The data is stored serialized in JSON format.

## TODO

 + Implement a REST web service API endpoint to create invoices and
   update/retrieve/delete client information.
 
