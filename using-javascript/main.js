/*global require*/

require.config({
    paths: {
        "jquery": "//code.jquery.com/jquery-2.1.3.min",
        "textfill": "//cdn.rawgit.com/jquery-textfill/jquery-textfill/master/source/jquery.textfill.min"
    },
    "shim": {
        "textfill": ["jquery"]
    }
});

require(["jquery", "textfill", "console"], function ($, textfill, console) {
    "use strict";
    
    $.ajax({
        dataType: "json",
        url: "../target/family-tree.small.json",
        success: function (data, textStatus, jqXHR) {
            var pxBoxSize, pxPerYear, dx, pxBoxSpacing,
                firstYear,
                div, x, y,
                p, person,
                f, family, parent, parents, child, children;
            
            pxBoxSize = 150;
            pxPerYear = 15;
            pxBoxSpacing = 150;
            dx = 0;
            firstYear = Infinity;

            for (p in data.people) {
                if (data.people.hasOwnProperty(p)) {
                    firstYear = Math.min(firstYear, data.people[p]["estimated-birth"]);
                    dx += 1;
                }
            }
            dx = pxBoxSize * dx;

            for (p in data.people) {
                if (data.people.hasOwnProperty(p)) {
                    person = data.people[p];
                    div = $('<div class="person" id="' + p + '"><span>' + person.name + '</span></div>');
                    x = dx * (person["x-position"] + 1);
                    y = (pxPerYear * (person["estimated-birth"] - firstYear));
                    div.css("left", x + "px");
                    div.css("top", y + "px");
                    if ($("#canvas")[0].width < x + pxBoxSize) {
                        $("#canvas")[0].width = x + pxBoxSize;
                    }
                    if ($("#canvas")[0].height < y + pxBoxSize) {
                        $("#canvas")[0].height = y + pxBoxSize;
                    }
                    $("#familyTree").append(div);
                }
            }
            
            for (f in data.families) {
                if (data.families.hasOwnProperty(f)) {
                    family = data.families[f];
                    if ($.isArray(family.parents)) {
                        for (p = family.parents.length - 1; p >= 0; p -= 1) {
                            person = family.parents[p];
                            if (!data.people.hasOwnProperty(person)) {
                                family.parents.splice(p, 1);
                            }
                        }
                        if (family.parents.length === 0) {
                            delete family.parents;
                        }
                    }
                    if ($.isArray(family.children)) {
                        for (p = family.children.length - 1; p >= 0; p -= 1) {
                            person = family.children[p];
                            if (!data.people.hasOwnProperty(person)) {
                                family.children.splice(p, 1);
                            }
                        }
                        if (family.children.length === 0) {
                            delete family.children;
                        }
                    }
                }
            }

            $(".person").textfill();
            
            setInterval(function () {
                var canvasElement, canvas, x, y, A, B, centerX,
                    f, family, parent1x, parent1y, parent2x, parent2y, lastParentBirthYear, firstChildBirthYear, childrenMinX, childrenMaxX,
                    p, person, o, otherPerson, moveLeft, moveRight;
                
                canvasElement = $("#canvas")[0];
                canvas = canvasElement.getContext('2d');
                
                centerX = canvasElement.width / 2;
                
                canvas.clearRect(0, 0, canvasElement.width, canvasElement.height);
                canvas.lineWidth = 5;

                // update people positions
                /*
                    TODO: two phases:
                      - first try to center on children
                      - then try to center on tree, with restrictions on movement based on children and parents
                */
                for (p in data.people) {
                    if (data.people.hasOwnProperty(p)) {
                        person = $("#" + p);
                        
                        if (person.position().left < centerX) {
                            moveLeft = false;
                            moveRight = true;
                        } else {
                            moveLeft = true;
                            moveRight = false;
                        }
                        
                        for (o in data.people) {
                            if (data.people.hasOwnProperty(o) && o !== p) {
                                otherPerson = $("#" + o);
                                
                                // if otherPerson can collide with person when moved horizontally
                                if (!(otherPerson.offset().top > person.offset().top + pxBoxSize + pxBoxSpacing || otherPerson.offset().top + pxBoxSize + pxBoxSpacing < person.offset().top)) {
                                    console.log("can collide: " + p + " and " + o);
                                    if (person.offset().left >= otherPerson.offset().left && person.offset().left - (otherPerson.offset().left + pxBoxSize) < pxBoxSpacing * 1.1) {
                                        // person will collide to the left
                                        moveLeft = false;
                                    }
                                    if (person.offset().left <= otherPerson.offset().left && otherPerson.offset().left - (person.offset().left + pxBoxSize) < pxBoxSpacing * 1.1) {
                                        // person will collide to the right
                                        moveRight = false;
                                    }
                                }
                            }
                        }
                        
                        // TODO: don't move towards centerX if distance to centerX < pxBoxSpacing / 10
                        
                        if (moveLeft) {
                            person.offset({ left: person.offset().left - pxBoxSpacing / 10 });
                        }
                        
                        if (moveRight) {
                            person.offset({ left: person.offset().left + pxBoxSpacing / 10 });
                        }
                    }
                }
                
                // update family lines
                for (f in data.families) {
                    if (data.families.hasOwnProperty(f)) {
                        family = data.families[f];
                        firstChildBirthYear = undefined;
                        childrenMinX = undefined;
                        childrenMaxX = undefined;
                        A = undefined;
                        B = undefined;
                        if ($.isArray(family.parents)) {
                            if (family.parents.length === 1) {
                                
                                // connect children to bottom of parent
                                parent1x = $("#" + family.parents[0]).offset().left + pxBoxSize / 2;
                                parent1y = $("#" + family.parents[0]).offset().top + pxBoxSize;
                                parent2x = parent1x;
                                parent2y = parent1y;
                                
                                lastParentBirthYear = data.people[family.parents[0]]["estimated-birth"];
                                
                            } else {
                                // two parents; create a line between them
                                
                                parent1x = $("#" + family.parents[0]).offset().left + pxBoxSize;
                                parent1y = $("#" + family.parents[0]).offset().top + pxBoxSize / 2;
                                parent2x = $("#" + family.parents[1]).offset().left;
                                parent2y = $("#" + family.parents[1]).offset().top + pxBoxSize / 2;
                                A = (parent2y - parent1y) / (parent2x - parent1x);
                                B = parent1y - parent1x * (parent2y - parent1y) / (parent2x - parent1x);
                                
                                canvas.beginPath();
                                canvas.moveTo(parent1x, parent1y);
                                canvas.lineTo(parent2x, parent2y);
                                canvas.stroke();
                                
                                lastParentBirthYear = Math.max(data.people[family.parents[0]]["estimated-birth"], data.people[family.parents[1]]["estimated-birth"]);
                                
                            }
                        }
                        if ($.isArray(family.children)) {
                            if (family.children.length === 1) {
                                
                                if ($.isArray(family.parents)) {
                                    person = $("#" + family.children[0]);

                                    if (Math.min(parent1x, parent2x) + pxBoxSize <= person.offset().left + pxBoxSize / 2 && person.offset().left + pxBoxSize / 2 <= Math.max(parent1x, parent2x) - pxBoxSize) {
                                        // perfectly vertical line
                                        canvas.beginPath();
                                        canvas.moveTo(person.offset().left + pxBoxSize / 2, person.offset().top);
                                        canvas.lineTo(person.offset().left + pxBoxSize / 2, A * (person.offset().left + pxBoxSize / 2) + B);
                                        canvas.stroke();

                                    } else {
                                        // skewed line
                                        canvas.beginPath();
                                        canvas.moveTo(person.offset().left + pxBoxSize / 2, person.offset().top);
                                        canvas.lineTo(person.offset().left + pxBoxSize / 2, A * ((parent1x + parent2x) / 2 + pxBoxSize / 2) + B);
                                        canvas.stroke();
                                    }
                                }
                                
                                
                            } else {
                            
                                for (p = family.children.length - 1; p >= 0; p -= 1) {
                                    person = $("#" + family.children[p]);
                                    if (firstChildBirthYear === undefined || firstChildBirthYear > data.people[family.children[p]]["estimated-birth"]) {
                                        firstChildBirthYear = data.people[family.children[p]]["estimated-birth"];
                                    }
                                    if (childrenMinX === undefined || childrenMinX > person.offset().left + pxBoxSize / 2) {
                                        childrenMinX = person.offset().left + pxBoxSize / 2;
                                    }
                                    if (childrenMaxX === undefined || childrenMaxX < person.offset().left + pxBoxSize / 2) {
                                        childrenMaxX = person.offset().left + pxBoxSize / 2;
                                    }
                                }
                                
                                if ($.isArray(family.parents)) {
                                    y = ((lastParentBirthYear + firstChildBirthYear) / 2 - firstYear) * pxPerYear + pxBoxSize / 2;
                                } else {
                                    y = firstChildBirthYear - firstYear - 20;
                                }
                                
                                canvas.beginPath();
                                canvas.moveTo(childrenMinX, y);
                                canvas.lineTo(childrenMaxX, y);
                                canvas.stroke();
                                
                                for (p = family.children.length - 1; p >= 0; p -= 1) {
                                    person = $("#" + family.children[p]);
                                    canvas.beginPath();
                                    canvas.moveTo(person.offset().left + pxBoxSize / 2, person.offset().top);
                                    canvas.lineTo(person.offset().left + pxBoxSize / 2, y);
                                    canvas.stroke();
                                }
                                
                                if ($.isArray(family.parents)) {
                                    if (family.parents.length === 1) {
                                        if (childrenMinX + pxBoxSize <= parent1x && parent1x <= childrenMaxX - pxBoxSize) {
                                            // perfectly vertical line
                                            canvas.beginPath();
                                            canvas.moveTo(parent1x, y);
                                            canvas.lineTo(parent1x, parent1y);
                                            canvas.stroke();

                                        } else {
                                            // skewed line
                                            canvas.beginPath();
                                            canvas.moveTo(person.offset().left + pxBoxSize / 2, person.offset().top);
                                            canvas.lineTo(person.offset().left + pxBoxSize / 2, (parent1y + parent2y) / 2);
                                            canvas.stroke();
                                        }
                                        
                                    } else {
                                        // TODO: multiple children; multiple parents
                                        if ((childrenMinX + pxBoxSize <= parent1x && parent1x <= childrenMaxX - pxBoxSize) || (childrenMinX + pxBoxSize <= parent2x && parent2x <= childrenMaxX - pxBoxSize)) {
                                            if (childrenMinX + pxBoxSize <= Math.min(parent1x, parent2x)) {
                                                x = (Math.min(Math.min(parent1x, parent2x), (parent1x + parent2x) / 2) + childrenMaxX) / 2;
                                                canvas.beginPath();
                                                canvas.moveTo(x, y);
                                                canvas.lineTo(x, A * x + B);
                                                canvas.stroke();
                                                
                                            } else {
                                                x = (Math.max(Math.max(parent1x, parent2x), (parent1x + parent2x) / 2) + childrenMinX) / 2;
                                                canvas.beginPath();
                                                canvas.moveTo(x, y);
                                                canvas.lineTo(x, A * x + B);
                                                canvas.stroke();
                                            }
                                            
                                        } else {
                                            // skewed line
                                            canvas.beginPath();
                                            canvas.moveTo((childrenMinX + childrenMaxX) / 2, y);
                                            canvas.lineTo((parent1x + parent2x) / 2, (parent1y + parent2y) / 2);
                                            canvas.stroke();
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                }
                
            }, 100);
        },
        error: function (jqXHR, textStatus, errorThrown) {
            $("#debug").html(errorThrown);
        }
    });
});
