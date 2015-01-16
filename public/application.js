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
});