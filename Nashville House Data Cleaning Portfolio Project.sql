/* Cleaning data in SQL queries */

SELECT *
FROM NashvilleHousingProject..NashvilleHouse




-------------------------------------------------
--Standardize Date Format
ALTER TABLE NashvilleHouse
ALTER COLUMN SaleDate date

/*another way to change SaleDate datatype is:
UPDATE NashvilleHouse
SET SaleDate = CONVERT(Date,SaleDate)
*/



-------------------------------------------------
--Populate Property Address data
SELECT *
FROM NashvilleHousingProject..NashvilleHouse
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHouse a
	JOIN NashvilleHouse b
	ON a.ParcelID=b.ParcelID
	AND a.UniqueID<>b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress=ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHouse a
	JOIN NashvilleHouse b
	ON a.ParcelID=b.ParcelID
	AND a.UniqueID<>b.UniqueID
WHERE a.PropertyAddress IS NULL



-------------------------------------------------
--Breaking out Address into Individual Columns (Address, City, State)
SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) Address
FROM NashvilleHousingProject..NashvilleHouse


ALTER TABLE NashvilleHouse
ADD PropertySplitAddress Nvarchar(255)

UPDATE NashvilleHouse
SET PropertySplitAddress=SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


ALTER TABLE NashvilleHouse
ADD PropertySplitCity Nvarchar(255)

UPDATE NashvilleHouse
SET PropertySplitCity=SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))






SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM NashvilleHouse


ALTER TABLE NashvilleHouse
ADD OwnerSplitAddress Nvarchar(255)

UPDATE NashvilleHouse
SET OwnerSplitAddress=PARSENAME(REPLACE(OwnerAddress,',','.'),3)


ALTER TABLE NashvilleHouse
ADD OwnerSplitCity Nvarchar(255)

UPDATE NashvilleHouse
SET OwnerSplitCity=PARSENAME(REPLACE(OwnerAddress,',','.'),2)


ALTER TABLE NashvilleHouse
ADD OwnerSplitState Nvarchar(255)

UPDATE NashvilleHouse
SET OwnerSplitState=PARSENAME(REPLACE(OwnerAddress,',','.'),1)



-------------------------------------------------
--Change Y and N to Yes and No in "Sold As Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHouse
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant='Y' THEN 'Yes'
		 WHEN SOldAsVacant='N' THEN 'No'
		 ELSE SoldAsVacant 
		 END
FROM NashvilleHouse


UPDATE NashvilleHouse
SET SoldAsVacant=
	CASE WHEN SoldAsVacant='Y' THEN 'Yes'
		 WHEN SOldAsVacant='N' THEN 'No'
		 ELSE SoldAsVacant 
	END



-------------------------------------------------
--Remove Duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) row_num
FROM NashvilleHouse
)
DELETE
FROM RowNumCTE
WHERE row_num>1



-------------------------------------------------
--Delete Unused Columns

ALTER TABLE NashvilleHouse
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
