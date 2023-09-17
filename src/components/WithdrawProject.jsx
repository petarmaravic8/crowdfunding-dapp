import { useState } from "react";
import { useEffect } from "react";
import { FaTimes } from "react-icons/fa";
import { toast } from "react-toastify";
import { preformRefundTo } from "../services/blockchain";
import { useGlobalState, setGlobalState } from "../store";
import { getUnbackedProjects } from "../services/blockchain";
import UnbackedProjects from "../components/UnbackedProjects";
//import { getBackers, loadProject } from "../services/blockchain";

const WithdrawProject = ({ project }) => {
  const [withdrawModal] = useGlobalState("withdrawModal");
  const [connectedAccount] = useGlobalState("connectedAccount");
  const [unbackedProjects] = useGlobalState("unbackedProjects");
  const [isHovered, setIsHovered] = useState(false);

  const handleMouseEnter = () => {
    setIsHovered(true);
  };

  const handleMouseLeave = () => {
    setIsHovered(false);
  };

  const projectStyle = {
    border: isHovered ? "2px solid red" : "none",
    // Add other styles for your project element here
  };

  useEffect(async () => {
    await getUnbackedProjects(connectedAccount);
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    //await getBackers(project?.id);
    //if (!amount) return;
    await preformRefundTo(project?.id, connectedAccount);
    toast.success("Project withdrawn successfully, will reflect in 30sec.");
    setGlobalState("withdrawModal", "scale-0");
  };

  return (
    <div
      className={`fixed top-0 left-0 w-screen h-screen flex
    items-center justify-center bg-black bg-opacity-50
    transform transition-transform duration-300 ${withdrawModal}`}
    >
      <div
        className="bg-white shadow-xl shadow-black
        rounded-xl w-11/12 md:w-2/5 h-7/12 p-6"
      >
        <form onSubmit={handleSubmit} className="flex flex-col">
          <div className="flex justify-between items-center">
            <p className="font-semibold">
              Transfer your donation to one of the projects
            </p>
            <button
              onClick={() => setGlobalState("withdrawModal", "scale-0")}
              type="button"
              className="border-0 bg-transparent focus:outline-none"
            >
              <FaTimes />
            </button>
          </div>

          <UnbackedProjects
            className="hover:bg-green-700 mt-5"
            unbackedProjects={unbackedProjects}
            fromProject={project}
            onClick={() => console.log("test")}
          />

          <div
            className=" flex justify-center px-6 py-2.5
            text-black font-medium text-md "
          >
            OR
          </div>

          <button
            type="submit"
            className="inline-block px-6 py-2.5 bg-green-600
            text-white font-medium text-md leading-tight
            rounded-full shadow-md hover:bg-green-700 mt-5"
          >
            Withdraw from {project?.title} project
          </button>
        </form>
      </div>
    </div>
  );
};

export default WithdrawProject;
