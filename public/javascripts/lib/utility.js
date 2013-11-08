//supplant
if (!String.prototype.supplant) {
    String.prototype.supplant = function (o) {
        return this.replace(
            /\{([^{}]*)\}/g,
            function (a, b) {
                var r = o[b];
                return typeof r === 'string' || typeof r === 'number' ? r : a;
            }
        );
    };
}

//sorting
var descendingObj = function(a, b, key){
	if(a[key] > b[key])
		return 1;
	if(a[key] > b[key])
		return -1;
	return 0;
};

var ascendingObj = function(a, b, key){
	if(b[key] > a[key])
		return 1;
	if(b[key] > a[key])
		return -1;
	return 0;
};

// filter functions
var filter = function(arr, f) {
	var output = [];

	for(var i=0; i<arr.length-1; i++) {
	if( f(arr[i]) ) {
		output.push(arr[i]);
		}
	}
	return output;
};

//expanded for arrays of arrays
    var filterDeep = function (arr, value, index){
        var output = [];
        for(var i = 0; i < arr.length; i++){
            if(value === arr[i][index])
                output.push(arr[i]);
        }
        return output;
    };

//search function
var search = function (arr, value, index){
        var re = new RegExp(value, 'gi');
        var filtered = [];
        for(var i = 0; i < arr.length; i++){
            if(arr[i][index].match(re)){
                filtered.push(arr[i]);
            }
        }
        return filtered;
    };


//for picking random properties in an object
function pickRandomProperty(obj) {
    var result;
    var count = 0;
    for (var prop in obj)
        if (Math.random() < 1/++count)
           result = prop;
    return result;
}

function pickRandomObject (arr) {
    var result;
    for (var i=0; i < arr.length-1; i++) {
        if (Math.random() < 1/i)
           result = arr[i];
   }
    return result;
}

//randomizer
var randomizer = function(a, b){
    a = Math.floor(Math.random()*101);
    b = Math.floor(Math.random()*101);

    if(a > b && a%b === 0){
        console.log(a);
        if (a < b && b%a === 0){
          console.log(b);
        }
    }
    else{
        console.log("Sorry. Cannot Compute!");
    }
};

//split array in array of arrays
var splitArray = function (arr, count){
        var newArray = [];
        var totArrays = 0;
        var rem = arr.length%count;
        var sub = count - rem;
        if(arr.length <= count){
            return arr;
        }
        else{
            if(arr.length%count === 0){
                totArrays = Math.floor(arr.length/count);
            }
            else{
                totArrays = Math.floor(arr.length/count) + 1;
            }
            for(var i = 0; i < totArrays; i++){
                var l = 0;
                if(i < totArrays - 1){
                l = count*(i+1);
                }
                else{
                l = (count*(i+1)) - sub;
                }
                var k = (count*i);
                newArray[i] = [];
                for(var j = k; j < l; j++){
                    newArray[i].push(arr[j]);
                }
            }
        }
        return newArray;
    };