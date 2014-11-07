# Function to determine whether the registration modal is scrolling or not
checkScroll = () ->
  if $('.reveal-modal')[0].scrollHeight > $('.reveal-modal').innerHeight()
    $('.reveal-modal').addClass("has-scroll")
  else
    $('.reveal-modal').removeClass("has-scroll")
$(document).ready(checkScroll)
$(window).resize(checkScroll)