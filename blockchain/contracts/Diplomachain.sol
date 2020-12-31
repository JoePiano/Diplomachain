// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Diplomachain {
    struct Diploma {
        bytes32 id;
        address owner;
        string speciality;
        string honors;
        string title;
        uint256 dateObtained; // timestamps format
    }

    struct Student {
        address id;
        string firstName;
        string lastName;
        string email;
        string nationality;
        string phoneNumber;
        string gender;
        bytes32[] diplomas;
    }

    mapping(address => uint256) private studentsIndexes;
    Student[] public students;
    uint256 public studentsCount;

    // we can know if a diploma exists or not
    mapping(bytes32 => uint256) public diplomasIndexes;
    Diploma[] public diplomas;
    uint256 public diplomasCount;
    mapping(bytes32 => uint256) public pendingDiplomasIndexes;
    Diploma[] public pendingDiplomas;
    uint256 public pendingDiplomasCount;

    // Let's say we have multiple universities, so it's a good practice to define admins addresses for now
    mapping(address => uint256) public adminsIndexes;

    constructor() {
        studentsCount = 0;
        diplomasCount = 0;
        pendingDiplomasCount = 0;
    }

    // ==========modifiers declaration==========
    modifier onlyAdmin() {
        require(adminsIndexes[msg.sender] != 0, "Admin not found");
        _;
    }
    modifier onlyStudent() {
        require(studentsIndexes[msg.sender] != 0, "Student not found");
        _;
    }

    // ==========events definition==========
    event LogRequestDiploma(address studentId);
    event LogAddDiploma(bytes32 diplomaId);

    // ==========Functions definition==========
    // verifyDiploma()
    function verifyDiploma(bytes32 diplomaId) public view returns (Diploma memory){
        require (diplomasIndexes[diplomaId] != 0, "You provided an invalid diploma identifier");
        return diplomas[diplomasIndexes[diplomaId] - 1];
    }

    // addStudent()
    function addStudent(
        address _id,
        string memory _firstName,
        string memory _lastName,
        string memory _email,
        string memory _nationality,
        string memory _phoneNumber,
        string memory _gender,
        bytes32[] memory _diplomas
    ) public onlyAdmin {
        require(studentsIndexes[_id] == 0, "Student already exists");
        studentsCount++;
        studentsIndexes[_id] = students.length + 1;
        students.push(
            Student(_id, _firstName, _lastName, _email, _nationality, _phoneNumber, _gender, _diplomas)
        );
    }
    // remove an element from an array and shift to avoid leaving gaps
    function removeItem(Diploma[] storage array, uint256 index) private {
        for (uint i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        delete array[array.length - 1];
        array.pop();
    }
    // addDiploma()
    function addDiploma(bytes32 _id) public onlyAdmin {
        require(diplomasIndexes[_id] == 0, "Diploma already exists");
        require(pendingDiplomasIndexes[_id] != 0, "Diploma request is not registered or has been removed");
        diplomasCount++;
        diplomasIndexes[_id] = diplomas.length + 1;
        diplomas.push(
            pendingDiplomas[pendingDiplomasIndexes[_id] - 1]
        );
        // get the student (owner) address
        address student_adr = pendingDiplomas[pendingDiplomasIndexes[_id] - 1].owner;
        // add the new diploma id to the student's diplomas ids array
        students[studentsIndexes[student_adr] - 1].diplomas.push(
            _id
        );
        // remove the diploma from the pending diplomas array
        removeItem(pendingDiplomas, pendingDiplomasIndexes[_id] - 1);
        delete pendingDiplomasIndexes[_id];
        pendingDiplomasCount--;
        emit LogAddDiploma(_id);
    }
    // isStudent()
    function isStudent() public view returns (bool) {
        return studentsIndexes[msg.sender] != 0;
    }
    // isAdmin()
    function isAdmin() public view returns (bool) {
        return adminsIndexes[msg.sender] != 0;
    }
    // getStudentIndex()
    function getStudentIndex(address studentId) public view returns (uint256) {
        require(studentsIndexes[studentId] != 0, "Student does not exist");
        return studentsIndexes[studentId] - 1;
    }
    // getDiplomaIndex()
    function getDiplomaIndex(bytes32 diplomaId) public view returns (uint256) {
        require(diplomasIndexes[diplomaId] != 0, "Diploma does not exist");
        return diplomasIndexes[diplomaId] - 1;
    }
    // getStudents()
    function getStudents() public onlyAdmin view returns (Student[] memory) {
        return students;
    }
    // getDiplomas()
    function getDiplomas() public onlyAdmin view returns (Diploma[] memory) {
        return diplomas;
    }
    // getStudentDiplomasIds()
    function getStudentDiplomasIds(address studentId) public view returns (bytes32[] memory) {
        require(studentsIndexes[studentId] != 0, "Student does not exist");
        require(msg.sender == studentId || adminsIndexes[msg.sender] != 0, "Only owner or admin are allowed");
        return students[studentsIndexes[studentId] - 1].diplomas;
    }
    // getStudentDiplomas()
    function getStudentDiplomas(address studentId) public view returns (Diploma[] memory) {
        require(studentsIndexes[studentId] != 0, "Student does not exist");
        require(msg.sender == studentId || adminsIndexes[msg.sender] != 0, "Only owner or admin are allowed");
        bytes32[] memory diplomas_ids = students[studentsIndexes[studentId] - 1].diplomas;
        Diploma[] memory full_diplomas = new Diploma[](diplomas_ids.length);
        for (uint256 i = 0; i < diplomas_ids.length; i++) {
            full_diplomas[i] = diplomas[diplomasIndexes[diplomas_ids[i]] - 1];
        }
        return full_diplomas;
    }
    // requestDiploma()
    function requestDiploma(
        string memory _speciality,
        string memory _honors,
        string memory _title,
        uint256 _dateObtained
    ) public onlyStudent {
        require(studentsIndexes[msg.sender] != 0, "Student does not exist");
        // generate a unique hash identifier for each diploma
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _speciality, _honors, _title, _dateObtained));
        pendingDiplomasCount++;
        pendingDiplomasIndexes[id] = pendingDiplomas.length + 1;
        pendingDiplomas.push(
            Diploma(id, msg.sender, _speciality, _honors, _title, _dateObtained)
        );
        emit LogRequestDiploma(msg.sender);
    }
}