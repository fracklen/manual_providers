$.get(url, function( data ) {
  userCtx = JSON.parse(data).userCtx
  console.log(userCtx);
  if(userCtx.name)
    window.location = "/secured_db/webpage/index.html"
});
