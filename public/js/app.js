$(function(){
    Connect({
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

    $("select.families").change(function(evt){
        var el = $(evt.target),family = el.val(), status = el.parent().attr("id") ;
        if(family != "---") {
            $("#"+status+" ul").html('').append('<li>loading...</li>');
            $.getJSON(base+'/workflow/'+family+'/'+status,function(r) {
                $("#"+status+" ul").html('');
                if(r.length < 1) {
                    $("#"+status+" ul").append('<li>N/A</li>');
                } else {
                    for(var i in r) {
                        $("#"+status+" ul").append('<li><i class="icon-leaf"></i>'
                                                  +'<a href="'+base+'/specie/'+r[i].taxon.lsid+'">'
                                                  +r[i].taxon.scientificName+'</a></li>');
                    }
                }
            });
        }
    });
    

    if (typeof schema == "object") {
        form = new onde.Onde($("#data"));
        form.render(schema,data,{collapsedCollapsibles: true});
        $("input[id*='-assessor']").attr("readonly",true);
        $("input[id*='-evaluator']").attr("readonly",true);
        $("input[id*='-criteria']").attr("readonly",true);
        $("input[id*='-criteria']").click(function(evt){
            $("#btn-criteria").click()
        })
        $("#data").submit(function(e){
            e.preventDefault();
            $("#data .actions button").attr("disabled",true).addClass("disabled").text("Wait...");
            var data = form.getData().data;
            $.post($("#data").attr("action"),{'data': JSON.stringify(data) } ,function(){
                location.href=$("#data").attr("action");
            });
            return false;
        });

        var got = {};
        $(".field-add.item-add").click(function(){
            setTimeout(function(){
                $("input[type=text]").each(function(i,e){
                    var input = $(e);
                    if(!got[input.prop("name")] && (input.prop("name").match(/references\[[0-9]+\].citation$/)?true:false)) {
                        got[input.prop("name")] = true;
                        input.autocomplete({ source:base+"/biblio" });
                        input.on('autocompleteselect',function(evt,ui){
                            var input = $(evt.target);
                            input.val(ui.item.label);
                            $("#"+input.prop("id").replace("citation","ref")).val(ui.item.value);
                            return false;
                        });
                    }
                });
            },1000);
        });

        $("input[type=text]").each(function(i,e){
            var input = $(e);
            if((input.prop("name").match(/references\[[0-9]+\].citation$/)?true:false)) {
                got[input.prop("name")] = true;
                input.on('autocompleteselect',function(evt,ui){
                    var input = $(evt.target);
                    input.val(ui.item.label);
                    $("#"+input.prop("id").replace("citation","ref")).val(ui.item.value);
                    return false;
                });
            }
        });
    }
});
