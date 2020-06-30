# BroadwayS2SExample

This examples shows a simple Broadway application which sends data to NiFi input port and reads a NiFi output port.

## Pre-requisite

Download and install the latest NiFi version from the oficial site: https://nifi.apache.org/download.html

Extract the tarball and execute the initial script:

    tar -zxf nifi-1.11.4-bin.tar.gz
    cd nifi-1.11.4
    bin/nifi.sh run

Import the `broadways2s.xml` template and start the flow

## Instructions

To run the application:

    mix deps.get
    
    mix compile
    
    mix test

    iex -S mix

    iex(2)> BroadwayS2S.dispatch
