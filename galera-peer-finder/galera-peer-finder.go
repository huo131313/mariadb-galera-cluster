/**
  读取执行如下命令名称生成的序号，
  mysqld --user=$user --wsrep-recover --log-error="$log_file"
**/

package main

import (
	"flag" // 命令行解析
	"fmt"
	"log"
	"net/http"
	"os"
)

var (
	position    = flag.String("position", "0:0", "The wsrep start position.")
)

func getWsrepStartPosition(w http.ResponseWriter, r *http.Request) {

	//--wsrep_start_position=a8b816d1-af68-11e9-9e7f-c3a26a591b26:559
	//domain : mysql-0.galera.default.svc.cluster.local

	//ns := *namespace
	//if ns == "" {
	//	ns = os.Getenv("POD_NAMESPACE")
	//}

	hostname, err := os.Hostname()
	if err != nil {
		log.Fatalf("Failed to get hostname: %s", err)
	}

	fmt.Fprintf(w,  *position + ":" + hostname) //这个写入到w的是输出到客户端的
}

func getDomain() {

	//ns := *namespace
	//if ns == "" {
	//	ns = os.Getenv("POD_NAMESPACE")
	//}
	//
	//var domainName string
	//
	//resolvConfBytes, err := ioutil.ReadFile("/etc/resolv.conf")
	//resolvConf := string(resolvConfBytes)
	//if err != nil {
	//	log.Fatal("Unable to read /etc/resolv.conf")
	//}
	//
	//var re *regexp.Regexp
	//if ns == "" {
	//	// Looking for a domain that looks like with *.svc.**
	//	re, err = regexp.Compile(`\A(.*\n)*search\s{1,}(.*\s{1,})*(?P<goal>[a-zA-Z0-9-]{1,63}.svc.([a-zA-Z0-9-]{1,63}\.)*[a-zA-Z0-9]{2,63})`)
	//} else {
	//	// Looking for a domain that looks like svc.**
	//	re, err = regexp.Compile(`\A(.*\n)*search\s{1,}(.*\s{1,})*(?P<goal>svc.([a-zA-Z0-9-]{1,63}\.)*[a-zA-Z0-9]{2,63})`)
	//}
	//if err != nil {
	//	log.Fatalf("Failed to create regular expression: %v", err)
	//}
	//
	//groupNames := re.SubexpNames()
	//result := re.FindStringSubmatch(resolvConf)
	//for k, v := range result {
	//	if groupNames[k] == "goal" {
	//		if ns == "" {
	//			// Domain is complete if ns is empty
	//			domainName = v
	//		} else {
	//			// Need to convert svc.** into ns.svc.**
	//			domainName = ns + "." + v
	//		}
	//		break
	//	}
	//}
	//
	//log.Printf("Determined Domain to be %s", domainName)

}

func main() {

	flag.Parse()

	http.HandleFunc("/wsrep", getWsrepStartPosition) //设置访问的路由
	err := http.ListenAndServe(":8899", nil) //设置监听的端口
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

