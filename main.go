package main

import (
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
)

func Handler() {
	fmt.Println("Hello from Go!")
}

func main() {
	lambda.Start(Handler)
}
