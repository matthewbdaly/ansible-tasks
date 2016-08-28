vcl 4.0;
# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
# 
# Below is a commented-out copy of the default VCL logic.  If you
# redefine any of these subroutines, the built-in logic will be
# appended to your code.
# sub vcl_recv {
#     if (req.restarts == 0) {
# 	if (req.http.x-forwarded-for) {
# 	    set req.http.X-Forwarded-For =
# 		req.http.X-Forwarded-For + ", " + client.ip;
# 	} else {
# 	    set req.http.X-Forwarded-For = client.ip;
# 	}
#     }
#     if (req.method != "GET" &&
#       req.method != "HEAD" &&
#       req.method != "PUT" &&
#       req.method != "POST" &&
#       req.method != "TRACE" &&
#       req.method != "OPTIONS" &&
#       req.method != "DELETE") {
#         /* Non-RFC2616 or CONNECT which is weird. */
#         return (pipe);
#     }
#     if (req.method != "GET" && req.method != "HEAD") {
#         /* We only deal with GET and HEAD by default */
#         return (pass);
#     }
#     if (req.http.Authorization || req.http.Cookie) {
#         /* Not cacheable by default */
#         return (pass);
#     }
#     return (lookup);
# }
# 
# sub vcl_pipe {
#     # Note that only the first request to the backend will have
#     # X-Forwarded-For set.  If you use X-Forwarded-For and want to
#     # have it set for all requests, make sure to have:
#     # set bereq.http.connection = "close";
#     # here.  It is not set by default as it might break some broken web
#     # applications, like IIS with NTLM authentication.
#     return (pipe);
# }
# 
# sub vcl_pass {
#     return (pass);
# }
# 
# sub vcl_hash {
#     hash_data(req.url);
#     if (req.http.host) {
#         hash_data(req.http.host);
#     } else {
#         hash_data(server.ip);
#     }
#     return (hash);
# }
# 
# sub vcl_hit {
#     return (deliver);
# }
# 
# sub vcl_miss {
#     return (fetch);
# }
# 
# sub vcl_fetch {
#     if (beresp.ttl <= 0s ||
#         beresp.http.Set-Cookie ||
#         beresp.http.Vary == "*") {
# 		/*
# 		 * Mark as "Hit-For-Pass" for the next 2 minutes
# 		 */
# 		set beresp.ttl = 120 s;
# 		return (hit_for_pass);
#     }
#     return (deliver);
# }
# 
# sub vcl_deliver {
#     return (deliver);
# }
# 
# sub vcl_error {
#     set obj.http.Content-Type = "text/html; charset=utf-8";
#     set obj.http.Retry-After = "5";
#     synthetic {"
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
# <html>
#   <head>
#     <title>"} + obj.status + " " + obj.response + {"</title>
#   </head>
#   <body>
#     <h1>Error "} + obj.status + " " + obj.response + {"</h1>
#     <p>"} + obj.response + {"</p>
#     <h3>Guru Meditation:</h3>
#     <p>XID: "} + req.xid + {"</p>
#     <hr>
#     <p>Varnish cache server</p>
#   </body>
# </html>
# "};
#     return (deliver);
# }
# 
# sub vcl_init {
# 	return (ok);
# }
# 
# sub vcl_fini {
# 	return (ok);
# }

acl purge {
        "127.0.0.1";
	"localhost";
}

sub vcl_recv {

  # Unset proxy header to mitigate the HTTPoxy vulnerability
  unset req.http.proxy;

  # Set X-Forwarded-For header for logging in nginx
  #remove req.http.X-Forwarded-For;
  #set    req.http.X-Forwarded-For = client.ip;
  if (req.restarts == 0) {
    if (req.http.X-Forwarded-For) {
      set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }
  }
  
  # Never cache POST requests
  if (req.method == "POST") {
    return (pass);
  }

  # Never cache cart, account, checkout or addons
  if (req.url ~ "^/(cart|my-account|checkout|addons)") {
    return (pass);
  }

  # Never cache adding to cart
  if ( req.url ~ "\?add-to-cart=" ) {
    return (pass);
  }

  # Never cache admin or login
  if ( req.url ~ "^/wp-(admin|login)" ) {
    return (pass);
  }

  # Never cache WooCommerce API
  if ( req.url ~ "wc-api" ) {
    return (pass);
  }

  # Remove has_js and CloudFlare/Google Analytics __* cookies and statcounter is_unique
  set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(_[_a-z]+|has_js|is_unique)=[^;]*", "");
  # Remove a ";" prefix, if present.
  set req.http.Cookie = regsub(req.http.Cookie, "^;\s*", "");

# Either the admin pages or the login
if (req.url ~ "/wp-(login|admin|cron)") {
        # Don't cache, pass to backend
        return (pass);
}

# Remove the wp-settings-1 cookie
set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "")
;

# Remove the wp-settings-time-1 cookie
set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?"
, "");

# Remove the wp test cookie
set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_cookie=[^;]+(; )?", "");

# Static content unique to the theme can be cached (so no user uploaded images)
# The reason I don't take the wp-content/uploads is because of cache size on bigger blogs
# that would fill up with all those files getting pushed into cache
if (req.url ~ "wp-content/themes/" && req.url ~ "\.(css|js|png|gif|jp(e)?g)") {
    unset req.http.cookie;
}

# Even if no cookies are present, I don't want my "uploads" to be cached due to their potential size
if (req.url ~ "/wp-content/uploads/") {
    return (pass);
}

# any pages with captchas need to be excluded
if (req.url ~ "^/contact/" || req.url ~ "^/links/domains-for-sale/")
      {
		return(pass);
      }

# Check the cookies for wordpress-specific items
if (req.http.Cookie ~ "wordpress_" || req.http.Cookie ~ "comment_") {
        # A wordpress specific cookie has been set
    return (pass);
}

	# allow PURGE from localhost
	if (req.method == "PURGE") {
		if (!client.ip ~ purge) {
			return(synth(405, "Not allowed."));
		}
		return (purge);
	}

	# Force lookup if the request is a no-cache request from the client
	if (req.http.Cache-Control ~ "no-cache") {
		return (pass);
	}

# Try a cache-lookup
return (hash);

}

sub vcl_backend_response {
	#set obj.grace = 5m;
    set beresp.grace = 5m;

}
