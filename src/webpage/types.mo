

module Types = {
    // Http
    public type HeaderField = (Text, Text);

    public type HttpRequest = {
        body: Blob;
        headers: [HeaderField];
        method: Text;
        url: Text;
    };

    public type HttpResponse = {
        status_code: Nat16;
        headers: [HeaderField];
        body: Blob;
        streaming_strategy: ?StreamingStrategy;
    };

    public type StreamingStrategy = {
        #Callback: {
            callback : StreamingCallback;
            token    : StreamingCallbackToken;
        };
    };
    public type StreamingCallback = query (StreamingCallbackToken) -> async (StreamingCallbackResponse);

    public type StreamingCallbackToken =  {
        content_encoding : Text;
        index            : Nat;
        key              : Text;
    };

    public type StreamingCallbackResponse = {
        body  : Blob;
        token : ?StreamingCallbackToken;
    };

    // Hash Tree
    public type Hash = Blob;
    public type Key = Blob;
    public type Value = Blob;
    public type HashTree = {
        #empty;
        #pruned : Hash;
        #fork : (HashTree, HashTree);
        #labeled : (Key, HashTree);
        #leaf : Value;
    };
}