//f: the form
//fieldn: the file
//newValue: the new value for the field

//In the parameters control, the field name contains a ".", 
//so, we need to have this simle routinue to set its value
//when the LOV window is closed

function _setFieldValue(f, fien, newvalue)
{

  if( newvalue == (void 0))
    return false;

  for( var i=0; i < f.elements.length; i++){

    var e = f.elements[i];
    if(e.name == fien)
    {
      e.value = newvalue;
      break;
    }
  }   
}

//use this method to add more entries to an field, the values are delimited by ";"
function  _addFieldValue(f, fien, newValue)
{

  if( newValue == (void 0))
    return false;

  var myfield = null;
  for( var i=0; i < f.elements.length;i++){
  
    if(f.elements[i].name == fien)
    {
      myfield = f.elements[i];            
      break;
    }
  }

  var oldValues;
  if( myfield.value.length > 0 )
    oldValues = myfield.value.split(";");
  else
    oldValues = new Array();
    
  var newValues = newValue.split(";");

  //removing the duplicated entries
  for(var j=0; j < newValues.length; j++)
  {
    for(var i=0; i< oldValues.length; i++) {

      if(newValues[j] == oldValues[i]) {
        newValues[j] = null;
        break;
      }      
    }
  }

  //merging the two arrays together into oldValues
  var orgLength = oldValues.length;
  for(var j =0; j< newValues.length; j++){
    if(newValues[j] != null){
      oldValues[orgLength] = newValues[j];
      orgLength++;
    }
  }

  myfield.value = oldValues.join(";");
  
}