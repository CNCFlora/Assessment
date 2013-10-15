$(function(){
    Connect({
        onlogin: function(user) {
            if(!logged) {
                $.post('/login','user='+JSON.stringify(user),function(){
                    location.reload();
                });
            }
        },
        onlogout: function(nothing){
            if(logged) {
                $.post('/logout',nothing,function(){
                    location.reload();
                });
            }
        }
    });
    $("#login a").click(function(){ Connect.login(); });
    $("#logout a").click(function(){ Connect.logout(); });
    $('form button[class*="btn-danger"]').each(function(i,e){
        $(e).parent().parent().submit(function(){
            return confirm("Confirma excluir esse recurso?");
        });
    });
    $("form.send-to").submit(function(){
        return confirm("Confirm?");
    });


    $("select.families").change(function(evt){
        var el = $(evt.target),family = el.val(), status = el.parent().attr("id") ;
        if(family != "---") {
            $("#"+status+" ul").html('').append('<li>loading...</li>');
            $.getJSON('/workflow/'+family+'/'+status,function(r) {
                $("#"+status+" ul").html('');
                if(r.length < 1) {
                    $("#"+status+" ul").append('<li>N/A</li>');
                } else {
                    for(var i in r) {
                        $("#"+status+" ul").append('<li><i class="icon-leaf"></i>'
                                                  +'<a href="/assessment/'+r[i]._id+'/'+status+'">'
                                                  +r[i].taxon.scientificName+'</a></li>');
                    }
                }
            });
        }
    });
});
