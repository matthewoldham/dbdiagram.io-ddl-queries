dbdiagram.io DDL Queries
===============

Queries to generate correctly formatted dbdiagram.io DDL

# Problem

dbdiagram.io(https://www.dbdiagram.io) is a nifty tool for generating database diagrams, but what if you already have an existing schema you want to reverse engineer? I found that simply copying and pasting my native schema DDL into that window did not correctly pick up primary keys or foreign key relationships.

# Solution

Simply run the query appropriate to your platform, substituting the correct schema name, and then copy/paste the output into a dbdiagram.io window to generate your schema diagram. These queries will generate just the components necessary for dbdiagram.io.

# License
[MIT](./LICENSE.md)
