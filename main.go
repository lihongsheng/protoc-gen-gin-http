package main

import (
	"flag"
	"github.com/singer-stack-lab/protoc-gen-gin-http/generator"
	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/types/pluginpb"
)

var (
	showVersion = flag.Bool("version", false, "print the version and exit")
	// 是允许为空的google.api 定义
	//omitempty       = flag.Bool("omitempty", true, "omit if google.api is empty")
	omitemptyPrefix = flag.String("omitempty_prefix", "", "omit if google.api is empty")
)

func main() {
	flag.Parse()
	protogen.Options{
		ParamFunc: flag.CommandLine.Set,
	}.Run(func(gen *protogen.Plugin) error {
		gen.SupportedFeatures = uint64(pluginpb.CodeGeneratorResponse_FEATURE_PROTO3_OPTIONAL)
		for _, f := range gen.Files {
			if !f.Generate {
				continue
			}
			generator.GenerateFile(gen, f, *omitemptyPrefix)
		}
		return nil
	})
}
