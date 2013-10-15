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
});
