import Types "types";
import Utils "utils";
import Text "mo:base/Text";
import CertifiedData "mo:base/CertifiedData";

actor {
    public type HttpRequest = Types.HttpRequest;
    public type HttpResponse = Types.HttpResponse;
    public type HeaderField = Types.HeaderField;
    public type HashTree = Types.HashTree;

    stable var title : Text = "DAO";

    system func postupgrade() {
        update_asset_hash();
    };

    public func set_title(t : Text) : async() {
        title := t;
        update_asset_hash();
    };


    // update certificate data hash tree when html data changing
    func update_asset_hash() {
        CertifiedData.set(Utils.hash_tree(asset_tree()));
    };

    func main_page(): Blob {
        return Text.encodeUtf8 (
        "<html><head><title>" # title # "</title></head><body>" # title # "</body></html>"
        )
    };

    public query func http_request(req : HttpRequest) : async HttpResponse {
        // check if / is requested
        if ((req.method, req.url) == ("GET", "/")) {
        // If so, return the main page with with right headers
            return {
                status_code = 200;
                headers = [ ("content-type", "text/html; charset=utf-8"), certification_header() ];
                body = main_page();
                streaming_strategy = null;
            }
        } else {
        // Else return an error code. Note that we cannot certify this response
        // so a user going to https://ce7vw-haaaa-aaaai-aanva-cai.ic0.app/foo
        // will not see the error message
            return {
                status_code = 404;
                headers = [ ("content-type", "text/plain") ];
                body = "404 Not found.\n This canister only serves /.\n";
                streaming_strategy = null;
            }
        }
    };

    func certification_header() : HeaderField {
        let cert = switch (CertifiedData.getCertificate()) {
                        case (?c) c;
                        case null {
                            // unfortunately, we cannot do
                            //   throw Error.reject("getCertificate failed. Call this as a query call!")
                            // here, because this function isn’t async, but we can’t make it async
                            // because it is called from a query (and it would do the wrong thing) :-(
                            //
                            // So just return erronous data instead
                            "getCertificate failed. Call this as a query call!" : Blob
                        }
                    };
        return
        ("ic-certificate",
            "certificate=:" # Utils.base64(cert) # ":, " #
            "tree=:" # Utils.base64(Utils.cbor_tree(asset_tree())) # ":"
        )
    };

    func asset_tree() : HashTree {
        #labeled ("http_assets",
            #labeled ("/",
                #leaf (Utils.h(main_page()))
            )
        );
    };
};