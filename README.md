Heroku buildpack: Play!
=========================

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpack) for [Play! framework](http://www.playframework.org/) apps.

*Note: This buildpack only applies to Play 1.2.x and 1.3.x apps. Play 2.x apps are handled by the [Scala buildpack](https://github.com/heroku/heroku-buildpack-scala)*

Usage
-----

Example usage:

    $ ls
    app	conf	lib	public	test

    $ heroku create

    $ git push heroku master
    ...
    -----> Heroku receiving push
    -----> Fetching custom build pack... done
    -----> Play! app detected
    -----> Installing Play!..... done
    -----> Installing ivysettings.xml..... done
    -----> Building Play! application...
           ~        _            _
           ~  _ __ | | __ _ _  _| |
           ~ | '_ \| |/ _' | || |_|
           ~ |  __/|_|\____|\__ (_)
           ~ |_|            |__/
           ~
           ~ play! 1.3.1, http://www.playframework.org
           ~
           1.3.1
           Building Play! application at directory ./
    ...

The buildpack will detect your app as using the Play! framework if it has an `application.conf` in a `conf` directory. Your dependencies will be resolved using `play dependencies` and your app precompiled with `play precompile`. If you don't provide a Procfile the build pack will default to launching your app with `play run --%prod -Dprecompiled=true`.

Play Versions
-------------

The buildpack will read the Play! version that your application expects from your dependencies.yml file. The version comes on the same line where you already declare a dependency on the Play! framework itself:

    - play 1.2.7

If you don't specify a version it will be defaulted for you and you'll see a warning message in your build output. It is a best practice to specify the version off the framework that you intend to use.

Once your application is live you can upgrade the Play! version simply by changing the version in your dependencies.yml. If you don't specify a version and use the default version your application will not be updated when the default version is updated. This is so that you don't have to deal with your application being upgraded unexpectedly.

Customizing Ivy
-----------

You can customize the Ivy execution by creating a `.ivy2-overlay` directory in your project and adding it to Git.
The contents of this directory will be copied over the default `.ivy2` directory.
In this way, you can add files such as `.ivy2-overlay/ivysettings.xml` to customize the Ivy execution.

Hacking
-------

To use this buildpack, fork it on Github.  Push up changes to your fork, then create a test app with `--buildpack <your-github-url>` and push to it.

For example one of the things that the build pack does is download and install the Play! framework that will be used to run your app. If you want to use a version of the framework other than those that are supported place a tar.gz of the framework in a public location and then alter the line that sets this variable in the compile script to point there:

    PLAY_URL="https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku-$VER_TO_INSTALL.tar.gz"

This will alter the behaviour to pull down and install your chosen version of Play! rather than the default.

Commit and push the changes to your buildpack to your Github fork, then push your sample app to Heroku to test. Once the push succeeds you should be able to run:

    $ heroku run bash

and then:

    $ play version

and you'll see the your chosen play version printed.

License
-------

Licensed under the MIT License. See LICENSE file.
