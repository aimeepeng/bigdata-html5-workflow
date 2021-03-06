<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title></title>
    <script type="text/javascript" src="js/jquery-1.8.1.min.js"></script>
</head>
<body>
<div>
    <div style="float: left; width: 92px;">
        <img src="images/hive.png"
             draggable="true" width="40" height="40"
             style="border:1px solid #c3c3c3;" ondragstart="dragStart(event)" id="hive">

        <img src="images/accept.png"
             draggable="true" width="40" height="40"
             style="border:1px solid #c3c3c3;" ondragstart="dragStart(event)" id="success">

        <img src="images/start.jpg"
             draggable="true" width="40" height="40"
             style="border:1px solid #c3c3c3;" ondragstart="dragStart(event)" id="start">

        <img src="images/jar.jpg"
             draggable="true" width="40" height="40"
             style="border:1px solid #c3c3c3;" ondragstart="dragStart(event)" id="jar">

        <img src="images/connect.png" width="40" height="40"
             style="border:1px solid #c3c3c3;" onclick="startLine()">


    </div>
    <div style="float: left;">
        <canvas id="canvas" width="900" height="550"
                style="border:1px solid #c3c3c3;"
                onmousedown="canvasMouseDown(event)"
                onmouseup="canvasMouseUp(event)"
                onmousemove="canvasMouseMove(event)"
                ondragover="canvasDragOver(event)"
                ondrop="canvasDrop(event)"
                ></canvas>
    </div>
</div>


<textarea rows="33" cols="95" id="content"></textarea>


<script type="text/javascript">
    var xmlContent = "";
    var mouseDownNode = "";
    var canvas = document.getElementById("canvas");
    var canvasContext = canvas.getContext("2d");
    var canvasWidth = parseInt(canvas.getAttribute("width"));
    var canvasHeight = parseInt(canvas.getAttribute("height"));
    var wantDrawLine = false;

    jQuery(function () {
        jQuery.ajax({
            type: "GET",
            url: "/html5/xml/hive_show_tables_20151113112213214.xml",
            dataType: "xml",
            async: false,
            success: function (data) {
                xmlContent = data;
            }
        });
        draw();
    });

    function startLine() {
        wantDrawLine = true;
    }

    function canvasMouseDown(ev) {
        if (wantDrawLine == true) {
            wantDrawLine = false;
            var startNode = "";
            var endNode = "";
            var evx = transClientX2CanvasX(parseInt(ev.clientX));
            var evy = transClientY2CanvasY(parseInt(ev.clientY));

            $(xmlContent).find("nodes").children("node").each(function (nodeIndex, node) {

                var name = $(node).children("name").text();
                var selected = $(node).attr("selected");
                if (selected == "true") {
                    startNode = name;
                } else {
                    var x = parseInt($(node).children("x").text());
                    var y = parseInt($(node).children("y").text());
                    if (evx > x && evx < x + 40 && evy > y && evy < y + 40) {
                        mouseDownNode = "";
                        endNode = name;
                        $(node).attr("selected", "true");
                    } else {
                        $(node).attr("selected", "false");
                    }
                }

            });


            //判断是否是有效的连线
            var sure = true;
            if (startNode != "" && endNode != "" && startNode != endNode) {
                $(xmlContent).find("hops").children("hop").each(function (hopIndex, hop) {     //查找所有nodes节点并遍历
                    var startN = $(hop).children("from").text();
                    var endN = $(hop).children("to").text();
                    if ((startNode == startN && endNode == endN) || (startNode == endN && endNode == startN)) {
                        sure = false;
                        alert("连线已存在");
                    }

                });


                if (sure == true) {
                    var hopString = '<hop>\n' +
                            '<type>connect</type>\n' +
                            '<from>' + startNode + '</from>\n' +
                            '<to>' + endNode + '</to>\n' +
                            '<enabled>Y</enabled>\n' +
                            '<evaluation>Y</evaluation>\n' +
                            '<unconditional>Y</unconditional>\n' +
                            '</hop>';
                    $(xmlContent).find("hops").append(hopString);
                    draw();
                }


            }

        } else {
            var evx = transClientX2CanvasX(parseInt(ev.clientX));
            var evy = transClientY2CanvasY(parseInt(ev.clientY));
            //点中目标是一个节点
            $(xmlContent).find("nodes").children("node").each(function (nodeIndex, node) {
                var x = parseInt($(node).children("x").text());
                var y = parseInt($(node).children("y").text());
                var name = $(node).children("name").text();

                if (evx > x && evx < x + 40 && evy > y && evy < y + 40) {
                    //点击的是节点
                    var selected = $(node).attr("selected");
                    if (selected == "true") {
                        //判断鼠标是否在删除按钮上
                        if (evx > x + 27 && evx < x + 39 && evy > y + 1 && evy < y + 13) {
                            //点击的是节点上面的删除按钮

                            //删除这个节点和这个节点上的所有连线
                            $(xmlContent).find("hops").children("hop").each(function (hopIndex, hop) {     //查找所有nodes节点并遍历
                                var startNode = $(hop).children("from").text();
                                var endNode = $(hop).children("to").text();
                                if (startNode == name || endNode == name) {
                                    $(hop).detach();
                                }
                            })
                            $(node).detach();
                            mouseDownNode = "";
                            return false;
                        } else {
                            mouseDownNode = name;
                        }
                    } else {
                        //要选中某个节点
                        mouseDownNode = name;
                        $(node).attr("selected", "true");
                    }
                } else {
                    //其他的节点设置为未选中
                    $(node).attr("selected", "false");
                }
            });

            //点中的目标是线
            $(xmlContent).find("hops").children("hop").each(function (hopIndex, hop) {     //查找所有nodes节点并遍历
                var startX = 0;
                var startY = 0;
                var endX = 0;
                var endY = 0;
                var startNode = $(hop).children("from").text();
                var endNode = $(hop).children("to").text();
                var enabled = $(hop).children("enabled").text();
                var evaluation = $(hop).children("evaluation").text();
                var unconditional = $(hop).children("unconditional").text();
                $(xmlContent).find("nodes").children("node").each(function (nodeIndex, node) {     //查找所有nodes节点并遍历
                    var name = $(node).children("name").text();
                    var x = parseInt($(node).children("x").text());
                    var y = parseInt($(node).children("y").text());
                    if (name == startNode) {
                        startX = x + 20;
                        startY = y + 20;
                    } else if (name == endNode) {
                        endX = x + 20;
                        endY = y + 20;
                    }

                });
                //判断点击的位置
                var middleX = (startX + endX) / 2;
                var middleY = (startY + endY) / 2;
                var conditionArcX = middleX - 6;
                var conditionArcY = middleY - 6;
                //删除按钮边框
                var deleteArcX = middleX + 6;
                var deleteArcY = middleY + 6;
                var r = 6;

                if (evx > conditionArcX - r && evx < conditionArcX + r && evy > conditionArcY - r && evy < conditionArcY + r) {
                    //点中的是条件按钮
                    if (enabled == "N") { //灰色
                        //变黑色
                        $(hop).children("enabled").text("Y");
                        $(hop).children("evaluation").text("Y");
                        $(hop).children("unconditional").text("Y");
                    } else if (enabled == "Y" && unconditional == "Y") { //黑色
                        //变绿色
                        $(hop).children("enabled").text("Y");
                        $(hop).children("evaluation").text("Y");
                        $(hop).children("unconditional").text("N");
                    } else if (enabled == "Y" && unconditional == "N" && evaluation == "Y") { //绿色
                        //变红色
                        $(hop).children("enabled").text("Y");
                        $(hop).children("evaluation").text("N");
                        $(hop).children("unconditional").text("N");
                    } else if (enabled == "Y" && unconditional == "N" && evaluation == "N") { //红色
                        //变灰色
                        $(hop).children("enabled").text("N");
                        $(hop).children("evaluation").text("N");
                        $(hop).children("unconditional").text("N");
                    }
                } else if (evx > deleteArcX - r && evx < deleteArcX + r && evy > deleteArcY - r && evy < deleteArcY + r) {
                    //点中的是删除按钮
                    $(hop).detach();
                }
            });

            draw();
        }
    }

    function canvasMouseUp(ev) {
        draw();
        mouseDownNode = "";
    }

    function canvasMouseMove(ev) {
        if (mouseDownNode.length > 0) {
            $(xmlContent).find("nodes").children("node").each(function (nodeIndex, node) {     //查找所有nodes节点并遍历
                var name = $(node).children("name").text();
                var evx = transClientX2CanvasX(parseInt(ev.clientX));
                var evy = transClientY2CanvasY(parseInt(ev.clientY));
                if (mouseDownNode == name) {
                    //不允许图标超出画图框
                    evx = (evx > 20) ? evx : 20;
                    evy = (evy > 20) ? evy : 20;
                    evx = (evx < canvasWidth - 20) ? evx : canvasWidth - 20;
                    evy = (evy < canvasHeight - 20) ? evy : canvasHeight - 20;

                    $(node).children("x").text(evx - 20);
                    $(node).children("y").text(evy - 20);
                    //跳出
                    return false;
                }
            });
            draw();
        } else {
            //正常的移动鼠标非拖拽
            //鼠标悬停变色？
        }

    }

    function canvasDragOver(ev) {
        //允许拖放
        ev.preventDefault();

    }

    function canvasDrop(ev) {
        ev.preventDefault();
        var type = ev.dataTransfer.getData("type");
        var evx = transClientX2CanvasX(parseInt(ev.clientX));
        var evy = transClientY2CanvasY(parseInt(ev.clientY));
        //不允许图标超出画图框
        evx = (evx > 20) ? evx : 20;
        evy = (evy > 20) ? evy : 20;
        evx = (evx < canvasWidth - 20) ? evx : canvasWidth - 20;
        evy = (evy < canvasHeight - 20) ? evy : canvasHeight - 20;

        //清除其他节点选中状态
        $(xmlContent).find("nodes").children("node").each(function (nodeIndex, node) {
            $(node).attr("selected", "false");
        });

        //生成node节点
        var nodeString = '<node selected="true">\n' +
                '<type>' + type + '</type>\n' +
                '<name>' + type + '_' + new Date().getMilliseconds() + '</name>\n' +
                '<x>' + (evx - 20) + '</x>\n' +
                '<y>' + (evy - 20) + '</y>\n' +
                '<label>开始</label>\n' +
                '</node>';
        $(xmlContent).find("nodes").append(nodeString);
        draw();

    }

    function dragStart(ev) {
        ev.dataTransfer.setData("type", ev.target.id);
    }


    //读取xml 并显示在canvas上
    function draw() {
        jQuery("#content").val((new XMLSerializer()).serializeToString(xmlContent));

        //清理画板
        canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);
        //画图标
        $(xmlContent).find("nodes").children("node").each(function (nodeIndex, node) {     //查找所有nodes节点并遍历
            var type = $(node).children("type").text();
            var name = $(node).children("name").text();
            var x = parseInt($(node).children("x").text());
            var y = parseInt($(node).children("y").text());
            var selected = $(node).attr("selected");
            var img = document.getElementById(type);
            var control = new Image();
            control.src = img.getAttribute("src");
            control.onload = function () {
                canvasContext.drawImage(control, x, y, 40, 40);
                if (selected == "true") {
                    canvasContext.strokeStyle = "blue";
                } else {
                    canvasContext.strokeStyle = "black";
                }

                //画节点边框
                canvasContext.lineWidth = 1;
                canvasContext.strokeRect(x, y, 40, 40);

                //画节点名称
                var textWidth = canvasContext.measureText(type).width;
                canvasContext.strokeText(type, x + 20 - (textWidth / 2), y + 52);

                //选中状态下可以删除
                if (selected == "true") {
                    //画删除按钮边框
                    var arcX = x + 33;
                    var arcY = y + 7;
                    var r = 6;
                    canvasContext.beginPath();
                    canvasContext.fillStyle = '#c3c3c3';
                    canvasContext.arc(arcX, arcY, r, 0, Math.PI * 2, true);
                    canvasContext.closePath();
                    canvasContext.fill();
                    //画删除按钮X
                    canvasContext.beginPath();
                    canvasContext.lineWidth = 1;
                    canvasContext.strokeStyle = "brown";
                    canvasContext.moveTo(arcX - r + 2.5, arcY - r + 2.5);
                    canvasContext.lineTo(arcX + r - 2.5, arcY + r - 2.5);
                    canvasContext.moveTo(arcX - r + 2.5, arcY + r - 2.5);
                    canvasContext.lineTo(arcX + r - 2.5, arcY - r + 2.5);
                    canvasContext.closePath();
                    canvasContext.stroke();
                }

            }


        });

        //画带箭头连线
        $(xmlContent).find("hops").children("hop").each(function (hopIndex, hop) {     //查找所有nodes节点并遍历
            var startX = 0;
            var startY = 0;
            var endX = 0;
            var endY = 0;
            var startNode = $(hop).children("from").text();
            var endNode = $(hop).children("to").text();
            var enabled = $(hop).children("enabled").text();
            var evaluation = $(hop).children("evaluation").text();
            var unconditional = $(hop).children("unconditional").text();


            $(xmlContent).find("nodes").children("node").each(function (nodeIndex, node) {     //查找所有nodes节点并遍历
                var name = $(node).children("name").text();
                var x = parseInt($(node).children("x").text());
                var y = parseInt($(node).children("y").text());
                if (name == startNode) {
                    startX = x + 20;
                    startY = y + 20;
                } else if (name == endNode) {
                    endX = x + 20;
                    endY = y + 20;
                }

            });

            //=====画连线=====
            canvasContext.beginPath();
            canvasContext.lineWidth = 0.9;
            if (enabled == "N") {
                canvasContext.strokeStyle = "gray";
            } else if (unconditional == "Y") {
                canvasContext.strokeStyle = "black";
            } else if (evaluation == "Y") {
                canvasContext.strokeStyle = "green";
            } else {
                canvasContext.strokeStyle = "red";
            }


            canvasContext.moveTo(startX, startY);
            canvasContext.lineTo(endX, endY);

            //画箭头
            var middleX = (startX + endX) / 2;
            var middleY = (startY + endY) / 2;
            var arrowHeight = 18;
            var arrowWidth = 6;
            var angle = Math.atan2(endY - startY, endX - startX);

            canvasContext.moveTo(middleX - arrowHeight * Math.cos(angle) - arrowWidth * Math.sin(angle),
                    middleY - arrowHeight * Math.sin(angle) + arrowWidth * Math.cos(angle));
            canvasContext.lineTo(middleX, middleY);
            canvasContext.lineTo(middleX - arrowHeight * Math.cos(angle) + arrowWidth * Math.sin(angle),
                    middleY - arrowHeight * Math.sin(angle) - arrowWidth * Math.cos(angle));

            canvasContext.closePath();
            canvasContext.stroke();

            //画条件按钮
            var conditionArcX = middleX - 6;
            var conditionArcY = middleY - 6;
            var r = 6;
            canvasContext.beginPath();
            canvasContext.fillStyle = canvasContext.strokeStyle;
            canvasContext.arc(conditionArcX, conditionArcY, r, 0, Math.PI * 2, true);
            canvasContext.closePath();
            canvasContext.fill();

            //画删除按钮边框
            var deleteArcX = middleX + 6;
            var deleteArcY = middleY + 6;
            var r = 6;
            canvasContext.beginPath();
            canvasContext.fillStyle = '#c3c3c3';
            canvasContext.arc(deleteArcX, deleteArcY, r, 0, Math.PI * 2, true);
            canvasContext.closePath();
            canvasContext.fill();
            //画删除按钮X
            canvasContext.beginPath();
            canvasContext.lineWidth = 1;
            canvasContext.strokeStyle = "brown";
            canvasContext.moveTo(deleteArcX - r + 2.5, deleteArcY - r + 2.5);
            canvasContext.lineTo(deleteArcX + r - 2.5, deleteArcY + r - 2.5);
            canvasContext.moveTo(deleteArcX - r + 2.5, deleteArcY + r - 2.5);
            canvasContext.lineTo(deleteArcX + r - 2.5, deleteArcY - r + 2.5);
            canvasContext.closePath();
            canvasContext.stroke();


        });


    }

    function transClientX2CanvasX(x) {
        var canvas = document.getElementById("canvas");
        var canvasX = canvas.offsetLeft;
        return parseInt(x) - parseInt(canvasX);

    }

    function transClientY2CanvasY(y) {
        var canvas = document.getElementById("canvas");
        var canvasY = canvas.offsetTop;
        return parseInt(y) - parseInt(canvasY);
    }


</script>

</body>
</html>
