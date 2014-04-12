ShadowSPDY
==========
[![Build Status](https://travis-ci.org/clowwindy/ShadowSPDY.svg?branch=master)](https://travis-ci.org/clowwindy/ShadowSPDY)

ShadowSPDY is a tunnel proxy which can help you get through firewalls. It is a
 variation of [Shadowsocks][1].
 
Usage
-----

ShadowSPDY is currently beta. Future versions may NOT be compatible with this 
version.

You can submit bugs and issues on the [issue tracker][2].

For those who are willing to help developing or testing, here's the manual.

    # install node.js v0.10 from http://nodejs.org/ first
    git clone https://github.com/clowwindy/ShadowSPDY.git
    cd ShadowSPDY/
    npm install
    vim config.json
    bin/splocal  # or bin/spserver
    # then point your browser proxy into "socks5 127.0.0.1:1081"

Protocol
--------

ShadowSPDY simply adds an SPDY layer into Shadowsocks. Thus it provides benefits 
from SPDY, such as low latency, low resource consumption.

### Shadowsocks

    |-------------------------|
    |          Socks5         |
    |-------------------------|
    |    Shadow Encryption    |
    |-------------------------|

### ShadowSPDY

    |-------------------------|
    |         Socks5          |
    |-------------------------|
    |          SPDY           |
    |-------------------------|
    |    Shadow Encryption    |
    |-------------------------|

License
-------

ShadowSPDY

Copyright (c) 2014 clowwindy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


[1]: https://github.com/clowwindy/shadowsocks
[2]: https://github.com/clowwindy/ShadowSPDY/issues
