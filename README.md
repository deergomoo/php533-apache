Usage
=====

This image will install Apache on a Centos 6.8 base, a variety of toolchain packages needed to compile PHP, then download and build PHP 5.3.3 from source. It then grabs the last version of Xdebug to work with 5.3.3 (v2.2.7), and installs and configures that to connect to the host machine from inside the container.

Most common extensions are enabled on the build, but the `./configure` lines can be tweaked as necessary. This should be largely re-usable with other versions of PHP, with only the `./configure`, Xdebug version, and `wget` lines that likely need changing. However, if you're looking for an even remotely supported PHP version (i.e. 5.5+) you almost certainly want to just grab it and the appropriate modules from your package manager.

Building and Running
====================

From the directory containing the Dockerfile:

`docker build -t php533-apache .`

Wait for the container to finish building. Depending on your machine and internet connection this could take 10 minutes or more.

Test that everything went okay:

`docker run -d -p 8000:80 php533-apache`

Go to localhost:8000 and you should see the `phpinfo()` page. To mount your project:

`docker run -d -p 8000:80 -p 4430:443 -v /path/to/your/project:/var/www/html/public php533-apache` 

Things To Note
==============

Obviously you can forward ports and tag things however you like. Also, if your project has its own `public` directory, mount to `/var/www/html` instead of `/var/www/html/public`. 

If you have any more complex requirements you'll have to load up a shell (`docker exec -it <container_id> bash`) and edit the config to your liking. The config for the default site is located at `/etc/httpd/sites-available/000-default.conf`.

To use Xdebug, have your editor or IDE listen on 127.0.0.1:9000 (default Xdebug port) and set up your path mappings. Xdebug is configured to autostart, so you don't need to faff around setting cookies.

If you're using Docker for Mac you'll need to configure this slightly differently due to networking limitations. Set up a local loopback alias on your host machine (`sudo ifconfig lo0 alias 10.254.254.254`), and have your `xdebug.remote_host` line in `/etc/php.ini` in the container point to this alias. If you're going to be reusing this image a lot, you're better off editing the Dockerfile to hardcode this alias in, otherwise you'll need to edit it every time you spin up a container. Also note that this alias won't survive a reboot, however [someone has put together a very useful little launch daemon to automate this on boot.](https://gist.github.com/ralphschindler/535dc5916ccbd06f53c1b0ee5a868c93)

Why Would I Want This?
======================

Because you're stuck supporting a horribly outdated version of PHP that no-one wants to pay to upgrade. Why else?

Attribution
===========

The entire `./configure` line and all the build requirements come straight from [this very useful article by Ben Ramsey.](https://benramsey.com/blog/2012/03/build-php-54-on-centos-62/) Reading it was far quicker than sifting through all of the myriad PHP build flags.