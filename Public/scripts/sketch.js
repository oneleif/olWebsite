
var data = {
    "points": [
               {
               "x": 10,
               "y": 10
               },
               {
               "x": 20,
               "y": 10
               },
               {
               "x": 10,
               "y": 20
               },
               {
               "x": 0,
               "y": 10
               },
               {
               "x": 10,
               "y": 0
               }
               ]
};

/* JSON
 {
 "points": [
 {
 "x": 10,
 "y": 10
 },
 {
 "x": 20,
 "y": 10
 },
 {
 "x": 10,
 "y": 20
 },
 {
 "x": 0,
 "y": 10
 },
 {
 "x": 10,
 "y": 0
 }
 ]
 }
 */

function setup() { 
    createCanvas(400, 400);
    //    data = loadJSON("test1.json");
} 

function draw() { 
    background(255);
    rect(20,20,100,100);
    drawJSON(data);
}

function drawJSON(data) {
    var halfWidth = width / 2
    var halfHeight = height / 2
    data.circles.forEach( function (point) {
                         ellipse(halfWidth - point.x, halfHeight - point.y, 10, 10);
                         });
    data.squares.forEach( function (point) {
                         rect(halfWidth - point.x, halfHeight - point.y, 10, 10);
                         });
    data.triangles.forEach( function (point) {
                           triangle(halfWidth - point.sx, halfHeight - point.sy, halfWidth - point.mx, halfHeight - point.my, halfWidth - point.ex, halfHeight - point.ey);
                           });
    data.points.forEach( function (point) {
                        point(halfWidth - point.x, halfHeight - point.y);
                        });
    data.lines.forEach( function (point) {
                       line(halfWidth - point.sx, halfHeight - point.sy, halfWidth - point.ex, halfHeight - point.ey);
                       });
}
