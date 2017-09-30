<h2>ExExpress</h2>

![Swift3](https://img.shields.io/badge/swift-3-blue.svg)
![Swift4](https://img.shields.io/badge/swift-4-blue.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![tuxOS](https://img.shields.io/badge/os-tuxOS-green.svg?style=flat)
![Travis](https://travis-ci.org/modswift/ExExpress.svg?branch=develop)

TODO

Checkout the ApacheExpress README.
ExExpress is a server-independent Express toolkit for Swift.
ApacheExpress is using that by providing the HTTP 'driver' for ExExpress.

## ApacheExpress

TODO: Cleanup the README.

### This is what you can do

Fair enough. So we integrated a tiny subset of 
[Noze.io](http://noze.io/)
to allow you to do just that. This is what it looks like:

```Swift
server.onRequest { req, res in
  res.writeHead(200, [ "Content-Type": "text/html" ])
  try res.end("<h1>Hello World</h1>")
}
```

Now you are saying, this is all nice and pretty. But what about Connect?
I want to write and reuse middleware!
Here you go:

```Swift
let app = server.connect()

app.use { req, res, next in
  console.info("Request is passing Connect middleware ...")
  res.setHeader("Content-Type", "text/html; charset=utf-8")
  // Note: we do not close the request, we continue with the next middleware
  try next()
}

app.use("/express/connect") { req, res, next in
  try res.write("<p>This is a random cow:</p><pre>")
  try res.write(vaca())
  try res.write("</pre>")
  res.end()
}
```

And Express? Sure, the ExExpress is about to leave:
```Swift
let app = server.express(cookieParser(), session())

app.get("/express/cookies") { req, res, _ in
  // returns all cookies as JSON
  try res.json(req.cookies)
}

app.get("/express/") { req, res, _ in
  let tagline = arc4random_uniform(UInt32(taglines.count))
  
  let values : [ String : Any ] = [
    "tagline"     : taglines[Int(tagline)],
    "viewCount"   : req.session["viewCount"] ?? 0,
    "cowOfTheDay" : cows.vaca()
  ]
  try res.render("index", values)
}
```

### Documentation

ApacheExpress documentation can be found at:
[docs.apacheexpress.io](http://docs.apacheexpress.io/).

### Who

**mod_swift**, **ApacheExpress** and **ExExpress** are brought to you by
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.

There is a `#mod_swift` channel on the [Noze.io Slack](http://slack.noze.io).
