$(function(){

    Connect({
        context: context,
        onlogin: function(user) {
            if(!logged) {
                $.post(base+'/login','user='+JSON.stringify(user),function(){
                    location.reload();
                });
            }
        },
        onlogout: function(nothing){
            if(logged) {
                $.post(base+'/logout',nothing,function(){
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

    var form = null;

    $("form.send-to").submit(function(evt){
        if(confirm("Confirm?")) {
            if(typeof form != "undefined" && form != null) {
                var data = form.getData().data;
                $.post($("#data").attr("action"),{'data': JSON.stringify(data)} ,function(){
                    $.post($(evt.target).attr("action"),{},function(){
                        location.href=$("#data").attr("action");
                    });
                });
            } else if($("#review-form").length >= 1){
                $.post($(evt.target).attr("action"),{},function(){
                    $("#review-form").submit();
                });
            } else {
                return true;
            }
        }
        return false;
    });
    
    if (typeof schema == "object") {
        form = new onde.Onde($("#data"));
        form.render(schema,data,{collapsedCollapsibles: true});

        $("input[id*='-assessor']").attr("readonly",true);
        $("input[id*='-evaluator']").attr("readonly",true);
        $("input[id*='-criteria']").attr("readonly",true);
        $("input[id*='-criteria']").click(function(evt){ $("#btn-criteria").click() });

        $("#data").submit(function(e){
            e.preventDefault();
            $("#data .actions button").attr("disabled",true).addClass("disabled").text("Wait...");
            var data = form.getData().data;
            $.post($("#data").attr("action"),{'data': JSON.stringify(data) } ,function(){
                location.href=$("#data").attr("action");
            });
            return false;
        });
    }
});

