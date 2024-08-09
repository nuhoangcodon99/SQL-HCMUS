USE master
GO
IF DB_ID('QLP') IS NOT NULL
	DROP DATABASE QLP
GO
CREATE DATABASE QLP
GO
USE QLP
GO

CREATE TABLE PHONG
(
	MaPhong CHAR(3),
	TinhTrang NVARCHAR(10),
	LoaiPhong NVARCHAR(10),
	DonGia INT

	CONSTRAINT PK_PHONG
	PRIMARY KEY(MaPhong),
	CONSTRAINT CK_PHONG_TinhTrang
	CHECK (TinhTrang = N'Rảnh' OR TinhTrang = N'Bận')
)
CREATE TABLE KHACH
(
	MaKH CHAR(3),
	HoTen NVARCHAR(40),
	DiaChi NVARCHAR(40),
	Dien INT

	CONSTRAINT PK_KHACH
	PRIMARY KEY(MaKH)
)
CREATE TABLE DATPHONG
(
	Ma INT,
	MaKH CHAR(3),
	MaPhong CHAR(3),
	NgayDP DATE,
	NgayTra DATE,
	ThanhTien INT

	CONSTRAINT PK_DATPHONG
	PRIMARY KEY(Ma)
)
GO
ALTER TABLE DATPHONG
ADD
	CONSTRAINT FK_DATPHONG_PHONG
	FOREIGN KEY(MaPhong)
	REFERENCES PHONG,
	CONSTRAINT FK_DATPHONG_KHACH
	FOREIGN KEY(MaKH)
	REFERENCES KHACH
GO
INSERT PHONG(MaPhong, TinhTrang, LoaiPhong, DonGia)
VALUES 
	('001', N'Rảnh', 'Vip', 100000),
	('002', N'Bận', 'Normal', 50000),
	('003', N'Rảnh', 'Vip', 100000)

INSERT KHACH(MaKH, HoTen, DiaChi, Dien)
VALUES
	('001', N'Nhung', N'Âu Cơ', 100000),
	('002', N'Đức', N'Âu Cơ', 100000),
	('003', N'Bình', N'Gò Vấp', 200000)
INSERT DATPHONG(Ma, MaKH, MaPhong, NgayDP, NgayTra, ThanhTien)
VALUES
	(1, '001', '002', '01/04/2023', '02/04/2023', 100000)
GO

--Tạo
CREATE PROCEDURE spDatPhong @MaKH CHAR(3), @MaPhong CHAR(3), @NgayDat DATE
AS
	Declare @checkMaKH int --check mã khách hàng
	Declare @checkMaPhong int --check mã phòng
	Declare @maDatPhong int --tạo mã đặt phòng

	Set @checkMaKH = 0
	Set @checkMaPhong = 0
	Set @maDatPhong = 0
	IF(EXISTS(SELECT * FROM KHACH WHERE MaKH = @MaKH))
	BEGIN
		PRINT N'Mã khách hàng hợp lệ'
		SET @checkMaKH = 1 --nếu mã khách hàng hợp lệ thì check = 1
	END
	ELSE
		PRINT N'Mã khách hàng không hợp lệ'
	IF(EXISTS(SELECT * FROM PHONG WHERE MaPhong = @MaPhong) AND (SELECT TinhTrang FROM PHONG WHERE MaPhong = @MaPhong) = N'Rảnh')
	BEGIN
		PRINT N'Mã phòng hợp lệ'
		SET @checkMaPhong = 1 --nếu mã phòng hợp lệ thì check = 1
	END
	ELSE
		PRINT N'Mã phòng không hợp lệ'
	IF(@checkMaKH = 1 AND @checkMaPhong = 1)
	BEGIN
	Set @maDatPhong = (SELECT MAX(Ma) FROM DATPHONG) + 1 --tạo mã đặt phòng bằng mã đặt phòng lớn nhất cộng 1
	INSERT DATPHONG(Ma, MaKH, MaPhong, NgayDP, NgayTra, ThanhTien)
	VALUES
		(@maDatPhong, @MaKH, @MaPhong, @NgayDat, NULL, NULL) --nhập thông tin đặt phòng
	UPDATE PHONG SET TinhTrang = N'Bận' WHERE MaPhong = @MaPhong --Update tình trạng phòng
	PRINT N'Đặt phòng thành công'
	END
	ELSE
		PRINT N'Đặt phòng không thành công'
GO
Exec spDatPhong '002', '001', '05/04/2023'
GO

--Tạo
CREATE PROCEDURE spTraPhong @madp INT, @maKH CHAR(3)
AS
	Declare @checkMaKH INT --check mã khách hàng
	Declare @checkMaDP INT --check mã đặt phòng

	Set @checkMaKH = 0
	Set @checkMaDP = 0
	IF(@maKH IN(SELECT MaKH FROM DATPHONG))
	BEGIN
		PRINT N'Khách hàng có đặt phòng'
		Set @checkMaKH = 1 --nếu khách hàng có đặt phòng thì check = 1
	END
	ELSE
		PRINT N'Khách hàng không có đặt phòng'
	IF(@madp IN(SELECT Ma FROM DATPHONG WHERE MaKH = @maKH))
	BEGIN
		PRINT N'Mã đặt phòng hợp lệ' --nếu khách hàng đặt đúng phòng này thì check = 1
		Set @checkMaDP = 1
	END
	ELSE
		PRINT N'Khách không đặt phòng này'
	IF(@checkMaDP = 1 AND @checkMaKH = 1)
	BEGIN
	Declare @ngaydp DATE
	Declare @maPhong char(3)

	Set @ngaydp = (SELECT NgayDP FROM DATPHONG WHERE Ma = @madp) --lấy ngày đặt phòng
	Set @maPhong = (SELECT MaPhong
					FROM DATPHONG
					WHERE Ma = @madp) --lấy mã phòng đặt
	UPDATE DATPHONG SET NgayTra = GETDATE() WHERE Ma = @madp --update ngày trả
	--update thành tiền
	UPDATE DATPHONG SET ThanhTien = ((SELECT DonGia
									FROM PHONG
									WHERE MaPhong = @maPhong) * DATEDIFF(DAY, GETDATE(), @ngaydp)) WHERE Ma = @madp
	UPDATE PHONG SET TinhTrang = N'Rảnh' WHERE MaPhong = @maPhong --update tình trạng phòng
	PRINT N'Trả phòng thành công'
	END
	ELSE
		PRINT N'Trả phòng không thành công'
Exec spTraPhong 2, '002'
SELECT * FROM PHONG
SELECT * FROM DATPHONG
SELECT * FROM KHACH

