Heroku buildpack: Play!
=========================

This is a [Heroku buildpack](http://devcenter.heroku.com/articles/buildpack) for [Play! framework](http://www.playframework.org/) apps.

Usage
-----

Example usage:

    $ ls
    app	conf	lib	public	test

    $ heroku create --stack cedar --buildpack http://github.com/heroku/heroku-buildpack-play.git

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
           ~ play! 1.2.3, http://www.playframework.org
           ~
           1.2.3
           Building Play! application at directory ./
    ...

The buildpack will detect your app as using the Play! framework if it has an `application.conf` in a `conf` directory. Your dependencies will be resolved using `play dependencies` and your app precompiled with `play precompile`. If you don't provide a Procfile the build pack will default to launching your app with `play run --%prod -Dprecompiled=true`.

Hacking
-------

To use this buildpack, fork it on Github.  Push up changes to your fork, then create a test app with `--buildpack <your-github-url>` and push to it.

For example one of the things that the build pack does is download and install the Play! framework that will be used to run your app. If you want to use a different version of the play framework place a tar.gz of the framework in a public location and then alter the line that sets this variable in the compile script to point there:

    PLAY_URL="https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku.tar.gz"

This will alter the behaviour to pull down and install your chosen version of Play! rather than the default.

Commit and push the changes to your buildpack to your Github fork, then push your sample app to Heroku to test. Once the push succeeds you should be able to run:

    $ heroku run bash

and then:

    $ play version

and you'll see the your chosen play version printed.
