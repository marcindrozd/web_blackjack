$(document).ready(function() {
  $(document).on('click', '#btn-hit', function() {
    $.ajax({
      type: 'POST',
      url: '/player/hit'
    }).done(function(msg) {
      $('div#game').replaceWith(msg);
    });
    return false;
  });
  $(document).on('click', '#btn-stay', function() {
    $.ajax({
      type: 'POST',
      url: '/player/stay'
    }).done(function(msg) {
      $('div#game').replaceWith(msg);
    });
    return false;
  });
  $(document).on('click', '#dealer-btn', function() {
    $.ajax({
      type: 'POST',
      url: '/dealer/hit'
    }).done(function(msg) {
      $('div#game').replaceWith(msg);
    });
    return false;
  });
});