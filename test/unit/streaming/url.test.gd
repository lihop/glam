# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const URL := preload("res://addons/glam/streaming/url.gd")

var url1: URL
var url2: URL
var url3: URL
var url4: URL
var url5: URL


func before_each():
	url1 = URL.new("http://example.com")
	url2 = URL.new("https://www.example.com/hello")
	url3 = URL.new("http://test.www.EXAMPLE.com:333/test")
	url4 = URL.new("https://www.example.com:44/hello?world=true&yes=true#something")
	url5 = URL.new("https://ww_W.Ex_Ampl-e.com:5555/hel.lo/t_o/the?what=True&yes=true#WorlD")


func test_invalid_url():
	assert_eq(URL.is_valid(""), false)
	assert_eq(URL.is_valid("hahaha"), false)
	assert_eq(URL.is_valid(".com/hahaha?invalid=true#lol"), false)
	assert_eq(URL.is_valid("http://"), false)

	assert_eq(URL.is_valid(url1.href), true)
	assert_eq(URL.is_valid(url2.href), true)
	assert_eq(URL.is_valid(url3.href), true)
	assert_eq(URL.is_valid(url4.href), true)
	assert_eq(URL.is_valid(url5.href), true)


func test_href():
	assert_eq(url1.href, "http://example.com/")
	assert_eq(url2.href, "https://www.example.com/hello")
	assert_eq(url3.href, "http://test.www.example.com:333/test")
	assert_eq(url4.href, "https://www.example.com:44/hello?world=true&yes=true#something")
	assert_eq(url5.href, "https://ww_w.ex_ampl-e.com:5555/hel.lo/t_o/the?what=True&yes=true#WorlD")


func test_origin():
	assert_eq(url1.origin, "http://example.com")
	assert_eq(url2.origin, "https://www.example.com")
	assert_eq(url3.origin, "http://test.www.example.com:333")
	assert_eq(url4.origin, "https://www.example.com:44")
	assert_eq(url5.origin, "https://ww_w.ex_ampl-e.com:5555")


func test_protocol():
	assert_eq(url1.protocol, "http:")
	assert_eq(url2.protocol, "https:")
	assert_eq(url3.protocol, "http:")
	assert_eq(url4.protocol, "https:")
	assert_eq(url5.protocol, "https:")


func test_host():
	assert_eq(url1.host, "example.com")
	assert_eq(url2.host, "www.example.com")
	assert_eq(url3.host, "test.www.example.com:333")
	assert_eq(url4.host, "www.example.com:44")
	assert_eq(url5.host, "ww_w.ex_ampl-e.com:5555")


func test_hostname():
	assert_eq(url1.hostname, "example.com")
	assert_eq(url2.hostname, "www.example.com")
	assert_eq(url3.hostname, "test.www.example.com")
	assert_eq(url4.hostname, "www.example.com")
	assert_eq(url5.hostname, "ww_w.ex_ampl-e.com")


func test_port():
	assert_eq(url1.port, -1)
	assert_eq(url2.port, -1)
	assert_eq(url3.port, 333)
	assert_eq(url4.port, 44)
	assert_eq(url5.port, 5555)


func test_tail():
	assert_eq(url1.tail, "/")
	assert_eq(url2.tail, "/hello")
	assert_eq(url3.tail, "/test")
	assert_eq(url4.tail, "/hello?world=true&yes=true#something")
	assert_eq(url5.tail, "/hel.lo/t_o/the?what=True&yes=true#WorlD")
