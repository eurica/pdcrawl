This is a script to crawl for errors across multiple domains. 

Features:
* Crawls multiple domains
* Find multiple kinds of dead dependencies (images, scripts, css) not just <A>'s 
* Combines dead links into a report at the end
* Can check for other HTTP errors, not just 404s

Originally, I had hoped to make this some kind of a service, but it tends to take a long time to check thousands of dependencies.  So it's just a script you have to run yourself (although you probably want to schedule it and email yourself the output).