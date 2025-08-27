package generator

import (
	"bytes"
	_ "embed"
	"strings"
	"text/template"
)

//go:embed template.tpl
var httpTemplate string

type ServiceDesc struct {
	ServiceType string // Greeter
	ServiceName string // helloworld.Greeter
	Metadata    string // api/helloworld/helloworld.proto
	Methods     []*MethodDesc
	MethodSets  map[string]*MethodDesc
}

type MethodDesc struct {
	// method
	Name         string
	OriginalName string // The parsed original name
	Num          int    // RPC 定义多个 url path ,Num会增加
	Request      string
	Reply        string
	Comment      string
	// http_rule
	Path         string
	Method       string
	HasVars      bool
	HasBody      bool
	Body         string
	ResponseBody string
	Vars         []string
}

func (s *ServiceDesc) execute() string {
	s.MethodSets = make(map[string]*MethodDesc)
	for _, m := range s.Methods {
		s.MethodSets[m.Name] = m
	}
	buf := new(bytes.Buffer)
	tmpl, err := template.New("http").Parse(strings.TrimSpace(httpTemplate))
	if err != nil {
		panic(err)
	}
	if err := tmpl.Execute(buf, s); err != nil {
		panic(err)
	}
	return strings.Trim(buf.String(), "\r\n")
}
