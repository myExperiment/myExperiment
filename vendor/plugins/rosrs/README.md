ROSRSClient
=================

Partial port of Python ROSRS_Session code to Ruby.

[This project [8]][ref8] is intended to provide a Ruby-callable API for [myExperiment [9]][ref9] to access [Research Objects [1]][ref1], [[2]][ref2] stored in RODL, using the [ROSRS API [3]][ref3].  The functions provided closely follow the ROSRS API specification.  The code is based on an implementation in Python used by the RO_Manager utility; a full implementat ROSRS test suite can be found in the [GitHub `wf4ever/ro-manager` project [7]][ref7].

[ref1]: http://www.wf4ever-project.org/wiki/pages/viewpage.action?pageId=2065079 "What is an RO?"

[ref2]: http://wf4ever.github.com/ro/ "Wf4Ever Research Object Model"

[ref3]: http://www.wf4ever-project.org/wiki/display/docs/RO+SRS+interface+6 "ROSRS interface (v6)"

[ref7]: https://github.com/wf4ever/ro-manager/blob/master/src/rocommand/ROSRS_Session.py "Python ROSRS_Session in RO Manager.  See also test suite: https://github.com/wf4ever/ro-manager/blob/master/src/rocommand/test/TestROSRS_Session.py"
 
[ref8]: https://github.com/gklyne/ruby-http-session "ruby-http-session project, or successor"

[ref9]: http://www.myexperiment.org/ "De Roure, D., Goble, C. and Stevens, R. (2009) The Design and Realisation of the myExperiment Virtual Research Environment for Social Sharing of Workflows. Future Generation Computer Systems 25, pp. 561-567. doi:10.1016/j.future.2008.06.010"


## Contents

* Contents
* Package structure
* API calling conventions
* A simple example
* Development setup
* URIs
* Further work
* References


## Package structure

Key functions are currently contained in four files:

* `lib/wf4ever/rosrs_session.rb`
* `lib/wf4ever/rdf_graph.rb`
* `lib/wf4ever/namespaces.rb`
* `lib/wf4ever/folders.rb`
* `test/test_rosrs_session`

The main functions provided by this package are in `rosrs_session`.  This module provides a class whose instances manage a session with a specified ROSRS service endpoint.  A service URI is provided when an instance is created, and is used as a base URI for accessing ROs and other resources using relative URI references.  Any attempt to access a resource on a different host or post is rejected.

`rdf_graph` implements a simplified interface to the [Ruby RDF library [4]][ref4], handling parsing of RDF from strings, serialization to strings and simplified search and access to individual triples.  Most of the functions provided are quite trivial; the module is intended to provide (a) a distillation of knowledge about how to perform desired functions using the RDF and associated libraries, and (b) a shim layer for adapting between different conventions used by the RDF libraries and the `rosrs_session` library.  The [Raptor library [5]][ref5] and its [Ruby RDF interface[6]][ref6] are used for RDF/XML parsing and serialization.

[ref4]: http://rdf.rubyforge.org/ "RDF.rb: Linked Data for Ruby"

[ref5]: http://librdf.org/raptor/ "Raptor RDF Syntax Library"

[ref6]: http://rdf.rubyforge.org/raptor/ "Raptor RDF Parser Plugin for RDF.rb"

`namespaces` provides definitions of URIs for namespaces and namespace terms used in RDF graphs.  These are in similar form to the namespaces provided by the RDF library.

`folders` contains objects to represent and traverse RO's folder structure.

`test_rosrs_session` is a test suite for all the above.  It serves to provide regression testing for implemented functions, and also to provide examples of how the various ROSRS API functions provided can be accessed.


## API calling conventions

Many API functions have a small number of mandatory parameters which are provided as normal positional parameters, and a (possibly larger) number of optional keyword parameters that are provided as a Ruby hash.  The Ruby calling convention of collecting multiple `key => value` parameter expressions into a single has is used.

Return values are generally in the form of an array, which can be used with parallel assignment for easy access to the return values.

Example:

    code, reason, headers, body = rosrs.do_request("POST", rouri,
        :body   => data
        :ctype  => "text/plain"
        :accept => "application/rdf+xml"
        :headers    => reqheaders)


## A simple example

Here is a flavour of how the `rosrs_session` module may be used:

    # Create an ROSRS session
    rosrs = ROSRSSession.new(
        "http://sandbox.wf4ever-project.org/rodl/ROs/", 
        "47d5423c-b507-4e1c-8")

    # Create a new RO
    code, reason, rouri, manifest = @rosrs.create_research_object("Test-RO-name",
        "Test RO for ROSRSSession", "TestROSRS_Session.py", "2012-09-28")
    if code != 201
        raise "Failed to create new RO: "+reason
    end

    # Aggregate a resource into the new RO
    res_body = %q(
        New resource body
        )
    options = { :body => res_body, :ctype => "text/plain" }

    # Create and aggregate "internal" resource in new RO
    code, reason, proxyuri, resourceuri = rosrs.aggregate_internal_resource(
        rouri, "data/test_resource",
        :body => res_body,
        :ctype => "text/plain")
    if code != 201
        raise "Failed to create new resource: "+reason

    # Create a new folder
    folder_contents = [{:name => 'test_data.txt', :uri => 'http://www.example.com/ro/file1.txt'},
                       {:uri => 'http://www.myexperiment.org/workflows/7'}]
    folder_uri = rosrs.create_folder(rouri, "Input Data", folder_contents).uri

    # Examine a folder
    folder = rosrs.get_folder(folder_uri)
    puts folder.name
    puts folder.contents.inspect




    # When finished, close session
    rosrs.close


## Development setup

Development has been performed using Ruby 1.8.7 on Ubuntu Linux 10.04 and 12.04.  The code uses `rubygems`, `json`, `rdf` and `rdf-raptor` libraries beyond the standard Ruby libraries.

The `rdf-raptor` Ruby library uses the Ubuntu `raptor-util` and `libraptor-dev` packages.  NOTE: the Ruby RDF documentation does not mention `libraptor-dev`, but I found that without this the RDF libraries would not work for parsing and serializing RDF/XML.

Once the environment is set up, I find the following statements are sufficient include the required libraries:

    require "wf4ever/rosrs_client"

## URIs

Be aware that the standard Ruby library provides a URI class, and that the RDF library provides a different, incompatible URI class:

    # Standard Ruby library URI:
    uri1 = URI("http://example.com/")
    
    # URI class used by RDF library:
    uri2 = RDF::URI("http://example.com")

These URIs are not equivalent, and are not even directly comparable.

Currently, the HTTP handling code uses the standard Ruby library URIs, and the RDF handling code uses URIs provided by the RDF library.  The `namespaces` module returns `RDF::URI` values.

I'm not currently sure if this will prove to cause problems.  Take care when dereferencing URIs obtained from RDF.

## Further work

At the time of writing this, the code is very much a work in progress.  Some of the things possibly yet to-do include:

* Fork project into the wf4ever organization.  Rename to rosrs_session.
* Complete the APi functions
* Work out strategy for dealing with different URI classes.
* When creating an RO, use the supplied RO information to create some initial annotations (similar to RO Manager)?
* Refactor `rosrs_session.rb` to separate out `http_session`
* May want to investigate "streaming" RDF data between HTTP and RDF libraries, or using RDF reader/writer classes, rather than transferring via strings.  Currently, I assume the RDF is small enough that this doesn't matter.
* Refactor test suite per tested module (may require simple HTTP server setup if HTTP factored out as above)


## References

[[1] _What is an RO?_][ref1]; Wf4Ever Research Object description and notes.

[[2] _Wf4Ever Research Object Model_][ref2]; Specification of RO model.

[[3] _Wf4ever ROSRS interface (v6)_][ref3]; Description of the HTTP/REST interface for accessing and updating Research Objects, implemented by Wf4Ever RODL.

[[4] `RDF.rb`][ref4]; Linked Data for Ruby

[[5] _Raptor_][ref5]; Raptor RDF Syntax Library

[[6] `rdf_raptor`][ref6]; Raptor RDF Parser Plugin for RDF.rb

[[7] _Python ROSRS\_Session in RO Manager_][ref7];  See also the test suite: [TestROSRS_Session.py ](https://github.com/wf4ever/ro-manager/blob/master/src/rocommand/test/TestROSRS_Session.py).

[[8] `ruby-http-session` project, or successor][ref8]

[[9] _myExperiment_][ref9];  "De Roure, D., Goble, C. and Stevens, R. (2009) The Design and Realisation of the myExperiment Virtual Research Environment for Social Sharing of Workflows. Future Generation Computer Systems 25, pp. 561-567. doi:10.1016/j.future.2008.06.010"


