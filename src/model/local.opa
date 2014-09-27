//
// src/model/local.opa
// @date: 03/2013
// @author: Diel Caroes
//
//  This module implements the datastructure for local storage. (client-side persistency)
//  (it contains client-only functions)
//  DataStructure: Single-linked list in a key-value memory
//  first_element: points to the start of the list
//    |
//    |
//    V
//  ---------    ---------
//  | d | --|--> | d |   |
//  ---------    ---------
//
//  d: the data (evt in this case)
//  & pointer to next cell
//  Last cell distinguished by having the same location and next-pointer
//
//  startPointer is saved on <pointerPosition>_data and points to the start of the list (or itself when empty lists)


client module Local{

    private int pointerPosition = 0;
  
    /*
        Get something from localstorage by its local id
     */
    private function getDataById(int id){
        unserialize(id);
    }

    /*
        Loop over the local space from 'from'
    */
    private function loopLocalspace(int from, (int, localData -> void) my_func){
        if(localStorageExists(from)){
            match(getDataById(from)){
                case {failure}: void
                case ~{success: content}:
                    my_func(from, content)//give the lambda 'my_func' the from and the content
                    if(from!=content.next){
                        loopLocalspace(content.next, my_func);//loop until next pointer is pointing to itself
                    }
            }
        }     
    }

    /*
        Save with a new next and time-val
    */
    private function saveNewNext(data, int id, int nextId){
        localData storageData = {data:data, next:nextId}
        serializedSave(storageData, id)
    }

    /*
        Save by keeping everything
    */
    private function save(localData oldStorageData, int id){
        serializedSave(oldStorageData, id)
    }

    /*
        First serialize the localData data-type, then save
    */
    private function serializedSave(d, int id){
        serializedContent = OpaSerialize.String.serialize(d)
        HTML5.setStorageString("{id}_data", serializedContent)
    }

    /*
        Get the data, then unserialize it
    */
    private function unserialize(int id){
        if(localStorageExists(id)){
            content=HTML5.getStorageString("{id}_data");
            option(localData) d=OpaSerialize.String.unserialize(content);
            match(d){
                case {some: _}: 
                      
                    {success: Option.get(d)}
                case {none}: 
 
                    {failure}
            }
        }else{

            {failure}
        }
        
    }

    /*
        Get the start position, which is the id of the first event
    */
    private function getStartPosition(){
        if(localStorageExists(pointerPosition)){
            content=HTML5.getStorageString("{pointerPosition}_data");
            option(startPointer) d=OpaSerialize.String.unserialize(content);

            match(d){
                case {some: _}: 
                    p = Option.get(d);
                    if(p.first_element==pointerPosition){//no point at saying there is still local content
                        {failure}
                    }else{
                        {success: p.first_element}
                    }
                case {none}: 
 
                    {failure}
            }

            
        } else {
          {failure}
        } 
    }


    /*
        Check for the existance of localstorage
    */
    function bool localStorageExists(int number){
        name = "{number}_data"
        HTML5.localStorageExists(name);
    }


    /*
        Add something to localstorage
    */
    function addNew(info, id){
        originalStart = 
            match(getStartPosition()){
                case {failure}: 
                    id;
                case ~{success: position}:
                    if(position == pointerPosition){
                        id;
                    }else{
                        position;
                    }   
            }

        Logging.print("Original start {originalStart}")


        startPointer s = {first_element:id}
        serializedSave(s, pointerPosition)
        saveNewNext(info, id, originalStart);
    }


    /*
        Delete something from localstorage by its ID
        we need to find the previous of our element-to-be-deleted and update it to the one element-to-be deleted was pointing at
    */
    function deleteById(int idDelete){
        //int FIRST=getStartPosition();
        match(getStartPosition()){
            case {failure}: 
                    void;
            case ~{success: FIRST}:

                match(getDataById(idDelete)){
                    case ~{success: itemForDelete}: 

                        function newNext(int other){//function that will either return the next if there is one or the other id specified
                            if(itemForDelete.next==idDelete){//last one
                                other
                            }else{
                                itemForDelete.next
                            }
                        }


                        if(idDelete==FIRST){
                            //the item we want to delete is the first one, (our pointer is pointing to it)
                            startPointer s = {first_element:newNext(pointerPosition)}
                            serializedSave(s, pointerPosition)
                        }else{
                            if(localStorageExists(FIRST)){
                                loopLocalspace(FIRST, function(id, d){
                                    if(d.next==idDelete){
                                        //we found the node which is pointing at element-to-be-deleted
                                        save({d with next:newNext(id)}, id)
                                    }
                                });
                            }else{
                                Logging.print("Unable to delete because localstoragespace is not valid")
                            } 
                        }
                        //the actual delete
                        HTML5.removeStorageKey("{idDelete}_data");

                    case {failure: _}: void;  //we cannot get the data needed for delete, so it was already deleted before
                }
        }    
    }


    /*
        Update at position 'id' of local linked-list
    */
    function updateById(newData, int id){
        if(localStorageExists(id)){
            //get the data
            match(getDataById(id)){
                case {failure}: void
                case ~{success: oldData}:
                    updatedLocalStorage = {oldData with data:newData}
                    save(updatedLocalStorage, id);
            }        
        }
    }

    /*
        Loop over entire local linked-list
    */
    function loopLocal(func){

        match(getStartPosition()){
            case ~{success: FIRST}:

                Logging.print("full localstorage")
                loopLocalspace(FIRST, function(id, d){
                    func(d.data)
                });

            case {failure}:
                
                Logging.print("empty localstorage")
                void
        }

    }

    /*
        Get the localstorage data from a certain id
    */
    function getStorageDataById(int id){

        match(getDataById(id)){
            case {failure}: 

                {failure}

            case ~{success: localData}: 

                {success: localData.data};
        }        
    }
  
}
  