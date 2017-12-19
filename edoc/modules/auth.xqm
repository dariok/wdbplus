xquery version "3.1";

module namespace wdba = "https://github.com/dariok/wdbplus/auth";
declare function wdba:getAuth($node as node(), $model as map(*)) {
    let $current := xmldb:get-current-user()
    return
    	if ($current = 'guest' or $model('res') = 'logout') then
            <span id="login">
                <form
                    enctype="multipart/form-data"
                    method="post">
                    <input
                        type="text"
                        id="user"/>
                    <input
                        type="password"
                        id="password"/>
                    <input
                        type="submit"
                        value="login"/>
                    <input
                        type="hidden"
                        name="query"
                        value="{request:get-parameter('query', '')}"/>
                    <input
                        type="hidden"
                        name="edition"
                        value="{request:get-parameter('edition', '')}"/>
                </form>
            </span>
        else
            <span id="logout">
                User: <a id="logout-button" alt="Click to logout" href="#">{$current}</a>
            </span>
};